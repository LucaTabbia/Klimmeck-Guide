import 'package:flutter/material.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/library/components/library_book_art.dart';
import 'package:klimmeck_guide/shared/components/cached_svg.dart';

import '../../../../../models/enums/library_book.dart';
import '../../../../../theme/kg_theme.dart';

/// Pergamena di un libro aperto: titolo fermo in testa sopra la sua linea,
/// [slivers] del contenuto che vi scorrono sotto; il nastro per tornare agli
/// scaffali sta sulla riga del titolo, a sinistra (D-06). Un solo
/// `CustomScrollView`, così le pagine costruiscono solo ciò che è a schermo
/// (D-20).
class LibraryBookFrame extends StatelessWidget {
  const LibraryBookFrame({
    super.key,
    required this.book,
    required this.onBack,
    required this.slivers,
    this.pinnedHeader,
    this.pinnedHeaderExtentOf,
    this.titleTrailing,
    this.titleAdjacent,
    this.onTitleTap,
    this.scrollController,
  });

  /// Il nastro sporge di poco dal bordo sinistro della pergamena.
  static const double _backBookmarkOverhang = 3;
  static const double _backBookmarkWidth = 74;

  static const Key titleBarKey = ValueKey('library.titleBar');
  static const Key ruleKey = ValueKey('library.titleRule');

  final LibraryBook book;
  final VoidCallback onBack;
  final List<Widget> slivers;

  /// Appeso sotto la linea del titolo e fermo: il contenuto gli scorre dietro
  /// e a riposo comincia sotto di lui.
  final Widget? pinnedHeader;

  /// Altezza che [pinnedHeader] copre a riposo, per la larghezza utile della
  /// pagina: quando cambia, il contenuto la segue con la stessa animazione.
  final double Function(double width)? pinnedHeaderExtentOf;

  /// In fondo alla riga del titolo, a destra.
  final Widget? titleTrailing;

  /// Subito dopo il titolo, sulla stessa riga.
  final Widget? titleAdjacent;

  /// Tocco sul titolo e su ciò che lo affianca.
  final VoidCallback? onTitleTap;
  final ScrollController? scrollController;

  /// Spazio fra la testata (o [pinnedHeader]) e il contenuto a riposo.
  static const double contentTopGap = 20;
  static const Duration pinnedHeaderSlideDuration = Duration(milliseconds: 300);

  /// Il nastro è nella fascia centrale di un'immagine quadrata: qui se ne
  /// mostra solo quella fascia, girata di mezzo giro perché sta sul lato
  /// sinistro. Sta sulla riga del titolo, sopra tutto il resto, e scende fino
  /// alla linea.
  Widget _backBookmark() => SizedBox(
    width: _backBookmarkWidth,
    height: _backBookmarkWidth / 2,
    child: ClipRect(
      child: OverflowBox(
        minHeight: _backBookmarkWidth,
        maxHeight: _backBookmarkWidth,
        child: RotatedBox(
          quarterTurns: 2,
          child: CachedSvg(
            url: book.backBookmarkUrl,
            width: _backBookmarkWidth,
            height: _backBookmarkWidth,
          ),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 50.0),
      child: Container(
        width: MediaQuery.of(context).size.width - 100,
        decoration: const BoxDecoration(color: KlimmeckGuideTheme.parchment),
        height: MediaQuery.of(context).size.height,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              children: [
                _TitleBar(
                  title: book.title,
                  ruleColor: book.ruleColor,
                  trailing: titleTrailing,
                  adjacent: titleAdjacent,
                  onTap: onTitleTap,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: LayoutBuilder(
                      builder: (context, constraints) => Stack(
                        children: [
                          CustomScrollView(
                            controller: scrollController,
                            physics: const AlwaysScrollableScrollPhysics(),
                            slivers: [
                              SliverToBoxAdapter(
                                child: AnimatedContainer(
                                  duration: pinnedHeaderSlideDuration,
                                  curve: Curves.easeInOut,
                                  height:
                                      contentTopGap +
                                      (pinnedHeaderExtentOf?.call(
                                            constraints.maxWidth,
                                          ) ??
                                          0),
                                ),
                              ),
                              ...slivers,
                              const SliverToBoxAdapter(
                                child: SizedBox(height: 120),
                              ),
                            ],
                          ),
                          if (pinnedHeader != null)
                            Positioned(
                              top: 0,
                              left: 0,
                              right: 0,
                              child: RepaintBoundary(child: pinnedHeader!),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              top: MediaQuery.paddingOf(context).top,
              left: -_backBookmarkOverhang,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onBack,
                child: _backBookmark(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Testata ferma della pagina: il titolo sotto la barra di stato e la doppia
/// linea del colore del libro che attraversa la pergamena.
class _TitleBar extends StatelessWidget {
  const _TitleBar({
    required this.title,
    required this.ruleColor,
    required this.trailing,
    required this.adjacent,
    required this.onTap,
  });

  static const double _trailingInset = 20;

  static const double _ruleGap = 2;
  static const double _titleFontSize = 20;
  static const double _titlePadding = 2;

  final String title;
  final Color ruleColor;
  final Widget? trailing;
  final Widget? adjacent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      key: LibraryBookFrame.titleBarKey,
      color: KlimmeckGuideTheme.parchment,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: MediaQuery.paddingOf(context).top),
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: double.infinity,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(vertical: _titlePadding),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onTap,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: KlimmeckGuideTheme.instance.headlineLarge
                            .copyWith(fontSize: _titleFontSize),
                      ),
                      if (adjacent != null)
                        Padding(
                          padding: const EdgeInsets.only(
                            left: KlimmeckGuideTheme.spacingSm,
                          ),
                          child: adjacent,
                        ),
                    ],
                  ),
                ),
              ),
              if (trailing != null)
                Positioned(
                  right: _trailingInset,
                  top: 0,
                  bottom: 0,
                  child: Center(child: trailing),
                ),
            ],
          ),
          Column(
            key: LibraryBookFrame.ruleKey,
            mainAxisSize: MainAxisSize.min,
            children: [
              _Rule(thickness: 2, color: ruleColor),
              const SizedBox(height: _ruleGap),
              _Rule(thickness: 1, color: ruleColor),
            ],
          ),
        ],
      ),
    );
  }
}

class _Rule extends StatelessWidget {
  const _Rule({required this.thickness, required this.color});

  final double thickness;
  final Color color;

  @override
  Widget build(BuildContext context) =>
      Container(height: thickness, width: double.infinity, color: color);
}
