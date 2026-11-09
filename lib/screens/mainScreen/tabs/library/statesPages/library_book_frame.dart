import 'package:flutter/material.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/library/components/library_book_art.dart';
import 'package:klimmeck_guide/shared/components/cached_svg.dart';

import '../../../../../models/enums/library_book.dart';
import '../../../../../theme/kg_theme.dart';

/// Pergamena di un libro aperto: titolo, [slivers] del contenuto e segnalibro
/// in basso a destra per tornare agli scaffali (D-06). Un solo
/// `CustomScrollView`, così le pagine costruiscono solo ciò che è a schermo
/// (D-20).
class LibraryBookFrame extends StatelessWidget {
  const LibraryBookFrame({
    super.key,
    required this.book,
    required this.onBack,
    required this.slivers,
  });

  final LibraryBook book;
  final VoidCallback onBack;
  final List<Widget> slivers;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 50.0),
      child: Container(
        width: MediaQuery.of(context).size.width - 100,
        decoration: const BoxDecoration(color: KlimmeckGuideTheme.parchment),
        height: MediaQuery.of(context).size.height,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 40.0, bottom: 20.0),
                      child: Center(
                        child: Text(
                          book.title,
                          style: KlimmeckGuideTheme.instance.headlineLarge,
                        ),
                      ),
                    ),
                  ),
                  ...slivers,
                  const SliverToBoxAdapter(child: SizedBox(height: 120)),
                ],
              ),
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: GestureDetector(
                onTap: onBack,
                child: SizedBox(
                  width: 100,
                  height: 100,
                  child: CachedSvg(url: book.bookmarkUrl),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
