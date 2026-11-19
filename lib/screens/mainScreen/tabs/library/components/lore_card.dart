import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:klimmeck_guide/models/enums/library_book.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/library/components/novelty_bookmark.dart';
import 'package:klimmeck_guide/shared/components/cached_svg.dart';

import '../../../../../models/lore.dart';
import '../../../../../theme/kg_theme.dart';

class LoreCard extends StatelessWidget {
  const LoreCard({super.key, required this.lore, this.newInBook});

  static const Key newMarkKey = ValueKey('loreCard.newMark');

  final Lore lore;

  /// Libro di cui portare la targhetta «Novità» (D-07); `null` se già vista.
  final LibraryBook? newInBook;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: SizedBox(
        width: MediaQuery.of(context).size.width - 160,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: SizedBox(
                width: MediaQuery.of(context).size.width - 160,
                child: Row(
                  children: [
                    Expanded(
                      child: AutoSizeText(
                        lore.name ?? '',
                        maxFontSize: 20,
                        minFontSize: 12,
                        style: KlimmeckGuideTheme.instance.specialText,
                      ),
                    ),
                    if (newInBook != null)
                      NoveltyBookmark(key: newMarkKey, book: newInBook!),
                  ],
                ),
              ),
            ),
            Row(
              children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width - 360,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 20.0),
                    child: AutoSizeText(
                      maxFontSize: 20,
                      minFontSize: 10,
                      lore.description ?? '',
                      style: KlimmeckGuideTheme.instance.bodyMedium,
                    ),
                  ),
                ),
                if (lore.imagePath != null)
                  SizedBox(
                    height: 200,
                    width: 200,
                    child: CachedSvg(url: lore.imagePath!),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 20.0),
              child: Container(
                width: MediaQuery.of(context).size.width / 2,
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: KlimmeckGuideTheme.darkBronze,
                      width: 1,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
