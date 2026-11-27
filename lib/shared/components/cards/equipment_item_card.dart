import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:klimmeck_guide/config/cloudinary_assets.dart';
import 'package:klimmeck_guide/models/equipment_item.dart';
import 'package:klimmeck_guide/shared/components/bookmark_ribbon.dart';
import 'package:klimmeck_guide/shared/components/cached_svg.dart';
import 'package:klimmeck_guide/shared/components/usages_pencil_counter.dart';

import '../../../theme/kg_theme.dart';

/// Il segnalibro mostra solo ciò che dice [isSelected]: lo stato indossato
/// arriva dal BE, la carta non lo anticipa.
class EquipmentItemCard extends StatelessWidget {
  const EquipmentItemCard({
    super.key,
    required this.equipmentItem,
    required this.size,
    this.isSelected,
    this.onTap,
    this.onLongPress,
    this.quantity,
  });

  final EquipmentItem equipmentItem;
  final double size;
  final bool? isSelected;
  final int? quantity;
  final Function(EquipmentItem)? onTap;
  final Function(EquipmentItem)? onLongPress;

  static final _cardBackgroundUrl = CloudinaryAssets.url(
    CloudinaryAssets.emptyCardSheet,
  );

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap?.call(equipmentItem),
      onLongPress: onLongPress != null
          ? () => onLongPress!(equipmentItem)
          : null,
      child: RepaintBoundary(
        child: Stack(
          children: [
            CachedSvg(url: _cardBackgroundUrl, width: size, height: size),
            Align(
              alignment: Alignment.center,
              child: SizedBox(
                height: size,
                width: size,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Spacer(),
                    CachedSvg(
                      url: equipmentItem.equipType!.imagePath,
                      height: size / 1.8,
                      width: size,
                    ),
                    Spacer(),
                    SizedBox(
                      height: (size / 6),
                      child: AutoSizeText(
                        equipmentItem.name ?? "",
                        maxFontSize: 24,
                        minFontSize: 4,
                        maxLines: 2,
                        textAlign: TextAlign.center,
                        style: KlimmeckGuideTheme.instance.bodyLarge.copyWith(
                          color:
                              equipmentItem.rarity?.color ??
                              KlimmeckGuideTheme.deepNight,
                          fontWeight: FontWeight.w800,
                          shadows: [
                            Shadow(
                              offset: Offset.zero,
                              blurRadius: 0.7,
                              color: KlimmeckGuideTheme.deepNight.withAlpha(
                                150,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Spacer(flex: 2),
                  ],
                ),
              ),
            ),
            Positioned(
              right: 0,
              top: 5,
              child: UsagesPencilCounter(
                value: (quantity ?? 0) > 0 ? quantity : null,
              ),
            ),
            if (isSelected case final marked?)
              CardBookmark(isMarked: marked, cardSize: size),
          ],
        ),
      ),
    );
  }
}
