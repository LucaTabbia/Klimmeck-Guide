import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:klimmeck_guide/config/cloudinary_assets.dart';
import 'package:klimmeck_guide/models/loot_item.dart';
import 'package:klimmeck_guide/shared/components/cached_svg.dart';
import 'package:klimmeck_guide/shared/components/usages_pencil_counter.dart';

import '../../../theme/kg_theme.dart';

class LootItemCard extends StatelessWidget {
  const LootItemCard({
    super.key,
    required this.lootItem,
    required this.size,
    this.onTap,
    this.quantity,
  });

  static final _cardBackgroundUrl = CloudinaryAssets.url(
    CloudinaryAssets.emptyCardSheet,
  );

  final Function(LootItem)? onTap;
  final LootItem lootItem;
  final double size;
  final int? quantity;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap != null ? () => onTap!(lootItem) : null,
      child: RepaintBoundary(
        child: Stack(
          alignment: Alignment.center,
          children: [
            CachedSvg(url: _cardBackgroundUrl, height: size, width: size),
            SizedBox(
              width: size,
              height: size,
              child: Column(
                children: [
                  Spacer(flex: 3),
                  if (lootItem.effect != null)
                    CachedSvg(
                      url: lootItem.effect!.imagePath,
                      height: (size / 6) * 2.5,
                      width: size,
                    )
                  else
                    SizedBox(height: (size / 6) * 2.5),
                  Spacer(),
                  _buildTextSection(
                    text: lootItem.name ?? "",
                    color:
                        lootItem.rarity?.color ?? KlimmeckGuideTheme.deepNight,
                  ),
                  Spacer(),
                  if (lootItem.power != null && lootItem.power != 0)
                    _buildTextSection(text: '${lootItem.power}'),
                  Spacer(flex: 3),
                ],
              ),
            ),
            Positioned(
              right: 0,
              top: 5,
              child: UsagesPencilCounter(value: _shownQuantity),
            ),
          ],
        ),
      ),
    );
  }

  /// Quantità scritta a matita sulla carta; nessuna copia, nessun numero.
  int? get _shownQuantity => (quantity ?? 0) > 0 ? quantity : null;

  Widget _buildTextSection({required String text, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3.0),
      child: SizedBox(
        height: (size / 6),
        child: AutoSizeText(
          text,
          maxFontSize: 24,
          minFontSize: 4,
          maxLines: 2,
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
      ),
    );
  }
}
