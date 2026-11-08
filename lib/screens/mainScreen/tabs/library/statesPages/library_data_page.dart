import 'package:flutter/material.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/library/components/library_book_art.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/library/components/lore_card.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/library/statesPages/library_book_frame.dart';
import 'package:klimmeck_guide/shared/components/dropdown.dart';

import '../../../../../models/enums/library_book.dart';
import '../../../../../models/enums/lore_type.dart';
import '../../../../../models/lore.dart';
import '../../../../../theme/kg_theme.dart';

typedef _Section = ({LoreType type, List<Lore> entries});

/// Pagina di un libro: una sezione per tipo con almeno una voce (D-06), resa
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

  /// Chiave stabile per sezione (Pitfall 3): una sezione che compare sopra non
  /// sposta lo stato aperto delle altre.
  static Key sectionKeyOf(LoreType type) => ValueKey<LoreType>(type);

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

  List<_Section> get _sections => [
    for (final type in widget.book.types)
      (
        type: type,
        entries: widget.lore.where((entry) => entry.type == type).toList(),
      ),
  ].where((section) => section.entries.isNotEmpty).toList();

  void _toggle(LoreType type) {
    setState(() {
      if (!_open.remove(type)) _open.add(type);
    });
  }

  @override
  Widget build(BuildContext context) {
    final sections = _sections;
    return LibraryBookFrame(
      book: widget.book,
      onBack: widget.onBack,
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
        for (final section in sections) ..._sectionSlivers(section),
      ],
    );
  }

  List<Widget> _sectionSlivers(_Section section) {
    final isOpen = _open.contains(section.type);
    return [
      SliverToBoxAdapter(
        child: DropdownHeader(
          key: LibraryDataPage.sectionKeyOf(section.type),
          sectionName: section.type.label,
          turns: isOpen ? 0.5 : 0,
          onTap: () => _toggle(section.type),
        ),
      ),
      if (isOpen)
        SliverPadding(
          padding: const EdgeInsets.only(left: 10, top: 10, bottom: 10),
          sliver: SliverList.builder(
            itemCount: section.entries.length,
            itemBuilder: (context, index) => LoreCard(
              lore: section.entries[index],
              isNew: widget.newLoreIds.contains(section.entries[index].id),
              newMarkInk: widget.book.newMarkInk,
            ),
          ),
        ),
    ];
  }
}
