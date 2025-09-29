import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:klimmeck_guide/shared/components/cached_svg.dart';

import '../../../../../theme/kg_theme.dart';

class BookType extends StatelessWidget {
  const BookType({super.key, required this.title, required this.imagePath, required this.onTap});

  final String title;
  final String imagePath;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(),
      child: SizedBox(
        width: MediaQuery.of(context).size.width / 3,
        height: MediaQuery.of(context).size.height / 2,
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height / 2 - 40,
              child: CachedSvg(url: imagePath),
            ),
            SizedBox(
              height: 40,
              child: AutoSizeText(
                title,
                maxFontSize: 20,
                minFontSize: 12,
                style: KlimmeckGuideTheme.instance.titleMedium.copyWith(
                  color: KlimmeckGuideTheme.primaryGold,
                  shadows: KlimmeckGuideTheme.bordersForText,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
