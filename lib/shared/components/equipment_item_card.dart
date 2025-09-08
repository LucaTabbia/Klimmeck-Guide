import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:klimmeck_guide/models/equipment_item.dart';

import '../../theme/kg_theme.dart';

class EquipmentItemCard extends StatelessWidget {
  const EquipmentItemCard({
    super.key,
    required this.equipmentItem,
    required this.size,
    required this.isSelected,
    this.onTap,
    this.onLongPress,
  });

  final EquipmentItem equipmentItem;
  final double size;
  final bool isSelected;
  final Function(EquipmentItem)? onTap;
  final Function(EquipmentItem)? onLongPress;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap != null ? () => onTap!(equipmentItem) : null,
      onLongPress: onLongPress != null ? () => onLongPress!(equipmentItem) : null,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          SvgPicture.asset("assets/icons/svg/sheets/emptySheet.svg", height: size, width: size),
          Positioned(
            top: size / 7,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(equipmentItem.equipType!.imagePath, height: size / 2, width: size),
                Padding(
                  padding: EdgeInsets.only(left: size / 10, right: size / 10),
                  child: SizedBox(
                    width: size - (size / 2.9),
                    height: size / 2 - (size / 4),
                    child: AutoSizeText(
                      maxFontSize: 24,
                      minFontSize: 4,
                      maxLines: 1,
                      textAlign: TextAlign.center,
                      equipmentItem.name?.toString() ?? "",
                      style: KlimmeckGuideTheme.instance.bodyLarge.copyWith(
                        color: equipmentItem.rarity!.color,
                        fontWeight: FontWeight.w800,
                        shadows: [
                          Shadow(
                            offset: Offset(0, 0),
                            blurRadius: 0.7,
                            color: KlimmeckGuideTheme.deepNight.withAlpha(150),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            top: !isSelected ? -(size / 2.5) : 0,
            left: 5,
            child: RotatedBox(
              quarterTurns: 3,
              child: SvgPicture.asset(
                "assets/icons/svg/bookmarkRed.svg",
                height: size / 3,
                width: size,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
