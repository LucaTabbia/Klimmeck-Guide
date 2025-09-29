import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:klimmeck_guide/models/spell.dart';
import 'package:klimmeck_guide/shared/components/cached_svg.dart';

import '../../../theme/kg_theme.dart';

class SpellCard extends StatelessWidget {
  static const _cardBackgroundUrl =
      "https://res.cloudinary.com/dzuhywp53/image/upload/v1757660771/emptyCardSheet_tva16h.svg";

  final Spell spell;
  final double size;

  const SpellCard({super.key, required this.spell, required this.size});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Stack(
        alignment: Alignment.center,
        children: [
          const CachedSvg(url: _cardBackgroundUrl),
          Align(
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    CachedSvg(url: spell.useType!.imagePath, height: size / 2.5, width: size / 2.5),
                    CachedSvg(
                      url: spell.energyDamage!.type!.imagePath,
                      height: size / 2.5,
                      width: size / 2.5,
                    ),
                  ],
                ),
                _buildTextSection(text: spell.name ?? ""),
                if (spell.energyDamage!.power != 0)
                  _buildTextSection(text: spell.energyDamage!.power.toString()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextSection({required String text}) {
    return SizedBox(
      height: size / 6,
      child: AutoSizeText(
        text,
        maxFontSize: 24,
        minFontSize: 4,
        maxLines: 1,
        textAlign: TextAlign.center,
        style: KlimmeckGuideTheme.instance.bodyLarge.copyWith(
          fontWeight: FontWeight.w800,
          shadows: [
            Shadow(
              offset: Offset.zero,
              blurRadius: 0.7,
              color: KlimmeckGuideTheme.deepNight.withAlpha(150),
            ),
          ],
        ),
      ),
    );
  }
}
