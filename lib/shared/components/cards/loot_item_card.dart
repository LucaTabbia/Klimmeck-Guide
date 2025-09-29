import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:klimmeck_guide/models/loot_item.dart';
import 'package:klimmeck_guide/shared/components/cached_svg.dart';

import '../../../theme/kg_theme.dart';

class LootItemCard extends StatelessWidget {
  static const _cardBackgroundUrl =
      "https://res.cloudinary.com/dzuhywp53/image/upload/v1757660771/emptyCardSheet_tva16h.svg";

  final Function(LootItem)? onTap;
  final bool? isSelected;
  final LootItem lootItem;
  final double size;

  const LootItemCard({
    super.key,
    required this.lootItem,
    required this.size,
    this.isSelected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap != null ? () => onTap!(lootItem) : null,
      child: RepaintBoundary(
        child: Stack(
          children: [
            // sfondo
            const CachedSvg(url: _cardBackgroundUrl),

            // contenuto
            Align(
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CachedSvg(url: lootItem.effect!.imagePath, height: size / 2.5, width: size),
                  _buildTextSection(text: lootItem.name ?? "", color: lootItem.rarity!.color),
                  if (lootItem.power != 0) _buildTextSection(text: lootItem.power.toString()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextSection({required String text, Color? color}) {
    return SizedBox(
      height: size / 6,
      child: AutoSizeText(
        text,
        maxFontSize: 24,
        minFontSize: 4,
        maxLines: 1,
        textAlign: TextAlign.center,
        style: KlimmeckGuideTheme.instance.bodyLarge.copyWith(
          color: color,
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
