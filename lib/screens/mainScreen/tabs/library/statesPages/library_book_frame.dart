import 'package:flutter/material.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/library/components/library_book_art.dart';
import 'package:klimmeck_guide/shared/components/cached_svg.dart';

import '../../../../../models/enums/library_book.dart';
import '../../../../../theme/kg_theme.dart';

/// Pergamena di un libro aperto: titolo, contenuto e segnalibro in basso a
/// destra per tornare agli scaffali (D-06).
class LibraryBookFrame extends StatelessWidget {
  const LibraryBookFrame({
    super.key,
    required this.book,
    required this.onBack,
    required this.child,
  });

  final LibraryBook book;
  final VoidCallback onBack;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 50.0),
      child: Container(
        width: MediaQuery.of(context).size.width - 100,
        decoration: BoxDecoration(color: KlimmeckGuideTheme.parchment),
        height: MediaQuery.of(context).size.height,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 40),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20.0),
                      child: Text(
                        book.title,
                        style: KlimmeckGuideTheme.instance.headlineLarge,
                      ),
                    ),
                    child,
                    const SizedBox(height: 120),
                  ],
                ),
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
