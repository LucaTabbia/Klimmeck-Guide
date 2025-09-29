import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:klimmeck_guide/models/equipment_item.dart';
import 'package:klimmeck_guide/shared/components/cached_svg.dart';

import '../../../theme/kg_theme.dart';

class EquipmentItemCard extends StatelessWidget {
  static const _cardBackgroundUrl =
      "https://res.cloudinary.com/dzuhywp53/image/upload/v1757660771/emptyCardSheet_tva16h.svg";
  static const _bookmarkUrl =
      "https://res.cloudinary.com/dzuhywp53/image/upload/v1757683920/bookmarkRed_jms0vk.svg";

  final EquipmentItem equipmentItem;
  final double size;
  final bool isSelected;
  final Function(EquipmentItem)? onTap;
  final Function(EquipmentItem)? onLongPress;

  const EquipmentItemCard({
    super.key,
    required this.equipmentItem,
    required this.size,
    required this.isSelected,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap != null ? () => onTap!(equipmentItem) : null,
      onLongPress: onLongPress != null ? () => onLongPress!(equipmentItem) : null,
      child: RepaintBoundary(
        child: Stack(
          children: [
            const CachedSvg(url: _cardBackgroundUrl),
            Align(
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CachedSvg(
                    url: equipmentItem.equipType!.imagePath,
                    height: size / 1.8,
                    width: size,
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: size / 10),
                    child: AutoSizeText(
                      equipmentItem.name ?? "",
                      maxFontSize: 24,
                      minFontSize: 4,
                      maxLines: 1,
                      textAlign: TextAlign.center,
                      style: KlimmeckGuideTheme.instance.bodyLarge.copyWith(
                        color: equipmentItem.rarity!.color,
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
                ],
              ),
            ),
            _BookmarkMarker(isSelected: isSelected, size: size),
          ],
        ),
      ),
    );
  }
}

class _BookmarkMarker extends StatelessWidget {
  final bool isSelected;
  final double size;

  const _BookmarkMarker({required this.isSelected, required this.size});

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      top: !isSelected ? -(size / 2.5) : 0,
      left: 5,
      child: const RotatedBox(
        quarterTurns: 3,
        child: CachedSvg(url: EquipmentItemCard._bookmarkUrl),
      ),
    );
  }
}
