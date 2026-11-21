import 'package:flutter/material.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/library/components/letter_bookmarks.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/library/components/lore_card.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/library/components/novelty_bookmark.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/library/statesPages/library_book_frame.dart';
import 'package:klimmeck_guide/config/cloudinary_assets.dart';
import 'package:klimmeck_guide/shared/components/cached_svg.dart';
import 'package:klimmeck_guide/shared/components/dropdown.dart';
import 'package:klimmeck_guide/utils/initial_letter.dart';

import '../../../../../models/enums/library_book.dart';
import '../../../../../models/enums/lore_type.dart';
import '../../../../../models/lore.dart';
import '../../../../../theme/kg_theme.dart';

typedef _Section = ({LoreType type, List<Lore> entries});

/// Pagina di un libro: una sezione per tipo con almeno una voce (D-06), le
/// lore nuove in testa, resa
/// a sliver così solo le card a schermo costruiscono la loro immagine; una
/// sezione chiusa non costruisce nulla (D-20).
class LibraryDataPage extends StatefulWidget {
  const LibraryDataPage({
    super.key,
    required this.book,
    required this.lore,
    required this.newLoreIds,
    required this.onBack,
  });

  static const String emptyBookLine =
      'Le pagine di questo libro sono ancora bianche.';
  static const Key emptyBookKey = ValueKey('library.emptyBook');
  static const Key loreDividerKey = ValueKey('library.loreDivider');

  /// Accanto al titolo: cala e ritira gli stendardi delle lettere.
  static const Key filtersToggleKey = ValueKey('library.filtersToggle');

  /// Sulla riga del titolo: chiude la sezione aperta che si sta leggendo.
  static const Key collapseKey = ValueKey('library.collapseSection');

  /// Chiave stabile per sezione (Pitfall 3): una sezione che compare sopra non
  /// sposta lo stato aperto delle altre.
  static Key sectionKeyOf(LoreType type) => ValueKey<LoreType>(type);

  /// Targhetta «Novità» sull'intestazione di una sezione che ne contiene una.
  static Key sectionNewMarkKeyOf(LoreType type) =>
      ValueKey('library.sectionNewMark.${type.name}');

  static const double _sectionNewMarkWidth = 70;

  /// Mezzo giro della freccia di una sezione che si apre o si chiude.
  static const Duration arrowTurnDuration = Duration(milliseconds: 300);

  final LibraryBook book;
  final List<Lore> lore;
  final Set<String> newLoreIds;
  final VoidCallback onBack;

  @override
  State<LibraryDataPage> createState() => _LibraryDataPageState();
}

class _LibraryDataPageState extends State<LibraryDataPage> {
  /// Sezioni aperte, per tipo: sopravvivono ai dati nuovi del libro (D-05).
  final Set<LoreType> _open = {};

  final ScrollController _scroll = ScrollController();
  final GlobalKey _bannersKey = GlobalKey();
  final Map<LoreType, GlobalKey> _headerKeys = {};

  /// Sezione aperta la cui intestazione è ferma in testa mentre le sue voci
  /// scorrono: a stendardi calati questi la coprono, e la riga del titolo
  /// offre di chiuderla.
  LoreType? _readingSection;

  /// Stendardi calati; ritirati, restano fuori solo le punte.
  bool _areFiltersOpen = false;

  /// Sezioni dell'ultima build, in ordine di pagina: lo scorrimento le legge
  /// da qui a ogni fotogramma, senza rifare il filtro.
  List<LoreType> _shownTypes = const [];

  /// Iniziale scelta sugli stendardi: stato di vista locale; `null` = tutte.
  /// Resta scelta anche a stendardi ritirati.
  String? _letter;

  Set<String> get _initials => {
    for (final entry in widget.lore) ?initialLetterOf(entry.name),
  };

  /// Un'iniziale sparita dal libro riporta a tutte le voci.
  String? _shownLetterAmong(Set<String> initials) =>
      initials.contains(_letter) ? _letter : null;

  List<_Section> _sectionsFor(String? letter) => [
    for (final type in widget.book.types)
      (
        type: type,
        entries: _newFirst(
          widget.lore.where(
            (entry) =>
                entry.type == type &&
                (letter == null || initialLetterOf(entry.name) == letter),
          ),
        ),
      ),
  ].where((section) => section.entries.isNotEmpty).toList();

  void _toggleFilters() => setState(() => _areFiltersOpen = !_areFiltersOpen);

  void _toggleLetter(String letter) => setState(
    () => _letter = _shownLetterAmong(_initials) == letter ? null : letter,
  );

  bool _isNew(Lore entry) => widget.newLoreIds.contains(entry.id);

  /// Le lore nuove aprono la sezione; dentro i due gruppi resta l'ordine del BE.
  List<Lore> _newFirst(Iterable<Lore> entries) => [
    ...entries.where(_isNew),
    ...entries.where((entry) => !_isNew(entry)),
  ];

  void _toggle(LoreType type) {
    setState(() {
      if (!_open.remove(type)) _open.add(type);
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  GlobalKey _headerKeyOf(LoreType type) =>
      _headerKeys.putIfAbsent(type, GlobalKey.new);

  static RenderBox? _boxOf(GlobalKey key) {
    final box = key.currentContext?.findRenderObject();
    return box is RenderBox && box.hasSize ? box : null;
  }

  /// Bordo alto della pagina che scorre: lì si fermano le intestazioni.
  double? get _stickLine => _boxOf(_bannersKey)?.localToGlobal(Offset.zero).dy;

  /// Bordo basso degli stendardi: sopra, il contenuto è coperto.
  double? get _coveredUntil {
    final banners = _boxOf(_bannersKey);
    return banners?.localToGlobal(Offset(0, banners.size.height)).dy;
  }

  /// L'ultima sezione la cui intestazione ha raggiunto la testa della pagina,
  /// se è aperta.
  LoreType? _findReadingSection() {
    final stickLine = _stickLine;
    if (stickLine == null) return null;
    for (final type in _shownTypes.reversed) {
      final header = _boxOf(_headerKeyOf(type));
      if (header == null) continue;
      if (header.localToGlobal(Offset.zero).dy > stickLine + _stickTolerance) {
        continue;
      }
      return _open.contains(type) ? type : null;
    }
    return null;
  }

  static const double _stickTolerance = 0.5;

  /// Le posizioni si leggono a layout fatto: la notifica di scorrimento e la
  /// build arrivano prima.
  void _followReadingSectionAfterLayout() => WidgetsBinding.instance
      .addPostFrameCallback((_) => _followReadingSection());

  void _followReadingSection() {
    if (!mounted) return;
    final reading = _findReadingSection();
    if (reading != _readingSection) setState(() => _readingSection = reading);
  }

  void _collapseReadingSection() {
    final type = _readingSection;
    if (type == null) return;
    setState(() {
      _open.remove(type);
      _readingSection = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _revealHeaderOf(type));
  }

  /// Riporta l'intestazione appena chiusa subito sotto gli stendardi.
  void _revealHeaderOf(LoreType type) {
    final header = _boxOf(_headerKeyOf(type));
    final coveredUntil = _coveredUntil;
    if (!mounted || !_scroll.hasClients) return;
    if (header == null || coveredUntil == null) return;
    final position = _scroll.position;
    final headerTop = header.localToGlobal(Offset.zero).dy;
    final target =
        position.pixels +
        headerTop -
        coveredUntil -
        LibraryBookFrame.contentTopGap;
    position.jumpTo(
      target.clamp(position.minScrollExtent, position.maxScrollExtent),
    );
  }

  @override
  Widget build(BuildContext context) {
    final initials = _initials;
    final letter = _shownLetterAmong(initials);
    final sections = _sectionsFor(letter);
    _shownTypes = [for (final section in sections) section.type];
    _followReadingSectionAfterLayout();
    return NotificationListener<ScrollUpdateNotification>(
      onNotification: (_) {
        _followReadingSectionAfterLayout();
        return false;
      },
      child: _buildFrame(sections, initials: initials, letter: letter),
    );
  }

  Widget _buildFrame(
    List<_Section> sections, {
    required Set<String> initials,
    required String? letter,
  }) {
    return LibraryBookFrame(
      book: widget.book,
      onBack: widget.onBack,
      scrollController: _scroll,
      titleAdjacent: widget.lore.isEmpty
          ? null
          : _FiltersToggle(isOpen: _areFiltersOpen),
      onTitleTap: widget.lore.isEmpty ? null : _toggleFilters,
      titleTrailing: _readingSection == null || !_areFiltersOpen
          ? null
          : _CollapseControl(
              sectionName: _readingSection!.label,
              onTap: _collapseReadingSection,
            ),
      pinnedHeader: widget.lore.isEmpty
          ? null
          : LetterBookmarks(
              key: _bannersKey,
              available: initials,
              selected: letter,
              onTap: _toggleLetter,
              isOpen: _areFiltersOpen,
            ),
      pinnedHeaderExtentOf: widget.lore.isEmpty
          ? null
          : _areFiltersOpen
          ? LetterBookmarks.extentFor
          : LetterBookmarks.foldedExtentFor,
      slivers: [
        if (sections.isEmpty)
          SliverToBoxAdapter(
            child: Text(
              LibraryDataPage.emptyBookLine,
              key: LibraryDataPage.emptyBookKey,
              textAlign: TextAlign.center,
              style: KlimmeckGuideTheme.instance.bodyMedium,
            ),
          ),
        for (final section in sections)
          SliverMainAxisGroup(slivers: _sectionSlivers(section)),
      ],
    );
  }

  List<Widget> _sectionSlivers(_Section section) {
    final isOpen = _open.contains(section.type);
    return [
      SliverPersistentHeader(
        pinned: true,
        delegate: _SectionHeaderDelegate(
          key: _headerKeyOf(section.type),
          isCoveredWhenStuck: _areFiltersOpen,
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: isOpen ? 0.5 : 0),
            duration: LibraryDataPage.arrowTurnDuration,
            curve: Curves.easeInOut,
            builder: (context, turns, _) => DropdownHeader(
              key: LibraryDataPage.sectionKeyOf(section.type),
              sectionName: section.type.label,
              turns: turns,
              badge: section.entries.any(_isNew)
                  ? NoveltyBookmark(
                      key: LibraryDataPage.sectionNewMarkKeyOf(section.type),
                      book: widget.book,
                      width: LibraryDataPage._sectionNewMarkWidth,
                    )
                  : null,
              onTap: () => _toggle(section.type),
            ),
          ),
        ),
      ),
      if (isOpen)
        SliverPadding(
          padding: const EdgeInsets.only(left: 10, top: 10, bottom: 10),
          sliver: SliverList.separated(
            itemCount: section.entries.length,
            separatorBuilder: (context, _) => const _LoreDivider(),
            itemBuilder: (context, index) => LoreCard(
              lore: section.entries[index],
              newInBook: _isNew(section.entries[index]) ? widget.book : null,
            ),
          ),
        ),
    ];
  }
}

/// Filo di bronzo fra una voce e la successiva: l'ultima della sezione non
/// ne ha.
class _LoreDivider extends StatelessWidget {
  const _LoreDivider();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 10),
    child: Center(
      child: Container(
        key: LibraryDataPage.loreDividerKey,
        width: MediaQuery.sizeOf(context).width / 2,
        height: 1,
        color: KlimmeckGuideTheme.darkBronze,
      ),
    ),
  );
}

/// Sulla riga del titolo: nome della sezione che si sta leggendo, più piccolo
/// del titolo, e freccia verso l'alto per chiuderla senza risalire.
class _CollapseControl extends StatelessWidget {
  const _CollapseControl({required this.sectionName, required this.onTap});

  static const double _nameFontSize = 13;
  static const double _arrowSize = 26;

  final String sectionName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: LibraryDataPage.collapseKey,
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            sectionName,
            style: KlimmeckGuideTheme.instance.titleMedium.copyWith(
              fontSize: _nameFontSize,
            ),
          ),
          const SizedBox(width: KlimmeckGuideTheme.spacingXs),
          RotatedBox(
            quarterTurns: 2,
            child: CachedSvg(
              url: CloudinaryAssets.url(CloudinaryAssets.arrowDown),
              width: _arrowSize,
              height: _arrowSize,
            ),
          ),
        ],
      ),
    );
  }
}

/// Intestazione di una sezione: resta ferma in testa alla pagina finché le
/// voci della sua sezione sono a schermo. A stendardi calati, lì è coperta:
/// svanisce sul posto mentre scendono e non si tocca.
class _SectionHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _SectionHeaderDelegate({
    required this.key,
    required this.isCoveredWhenStuck,
    required this.child,
  });

  /// 42 di riga più il filo di bronzo.
  static const double _extent = 43;

  final Key key;
  final bool isCoveredWhenStuck;
  final Widget child;

  @override
  double get minExtent => _extent;

  @override
  double get maxExtent => _extent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final isCovered = isCoveredWhenStuck && shrinkOffset > 0;
    return IgnorePointer(
      key: key,
      ignoring: isCovered,
      child: AnimatedOpacity(
        opacity: isCovered ? 0 : 1,
        duration: LetterBookmarks.slideDuration,
        child: ColoredBox(color: KlimmeckGuideTheme.parchment, child: child),
      ),
    );
  }

  @override
  bool shouldRebuild(_SectionHeaderDelegate oldDelegate) => true;
}

/// Accanto al titolo del libro: freccia in giù a stendardi ritirati, in su a
/// stendardi calati. Il tocco è della riga del titolo.
class _FiltersToggle extends StatelessWidget {
  const _FiltersToggle({required this.isOpen});

  static const double _arrowSize = 26;

  final bool isOpen;

  @override
  Widget build(BuildContext context) {
    return AnimatedRotation(
      key: LibraryDataPage.filtersToggleKey,
      turns: isOpen ? 0.5 : 0,
      duration: LetterBookmarks.slideDuration,
      child: CachedSvg(
        url: CloudinaryAssets.url(CloudinaryAssets.arrowDown),
        width: _arrowSize,
        height: _arrowSize,
      ),
    );
  }
}
