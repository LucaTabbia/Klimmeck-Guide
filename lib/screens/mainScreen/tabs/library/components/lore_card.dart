import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:klimmeck_guide/shared/components/cached_svg.dart';

import '../../../../../models/lore.dart';
import '../../../../../theme/kg_theme.dart';

class LoreCard extends StatelessWidget {
  const LoreCard({super.key, required this.lore});

  final Lore lore;

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
                child: AutoSizeText(
                  lore.name!,
                  maxFontSize: 20,
                  minFontSize: 12,
                  style: KlimmeckGuideTheme.instance.specialText,
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
                      lore.description!,
                      style: KlimmeckGuideTheme.instance.bodyMedium,
                    ),
                  ),
                ),
                if (lore.image != null)
                  SizedBox(height: 200, width: 200, child: CachedSvg(url: lore.image!)),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 20.0),
              child: Container(
                width: MediaQuery.of(context).size.width / 2,
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: KlimmeckGuideTheme.darkBronze, width: 1)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
