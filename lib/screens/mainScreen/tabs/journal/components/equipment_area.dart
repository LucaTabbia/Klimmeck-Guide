import 'package:flutter/material.dart';

import '../../../../../models/enums/equip_type.dart';
import '../../../../../theme/kg_theme.dart';

class EquipmentArea extends StatelessWidget {
  const EquipmentArea({
    super.key,
    required this.borderColor,
    required this.onTap,
    required this.baseWidth,
    required this.selectedTypes,
    required this.baseHeight,
    required this.type,
    this.isRight = false,
  });

  final double baseWidth;
  final double baseHeight;
  final EquipType type;
  final List<EquipType>? selectedTypes;
  final Color borderColor;
  final bool isRight;
  final Function(List<EquipType>) onTap;

  @override
  Widget build(BuildContext context) {
    final double height = baseHeight / type.ratios.mannequinRatio;
    final double originalWidth = height * type.ratios.aspectRatio;
    final actualWidth = getActualWidth(originalWidth);

    final left = isRight
        ? null
        : (baseWidth / 2) - (type == EquipType.greaves ? actualWidth / 2 : originalWidth / 2) + 5;
    final right = isRight ? (baseWidth / 2) - (originalWidth / 2) + 4 : null;

    final top = baseHeight / type.ratios.positionRatio + baseHeight * type.ratios.addedTop;

    return Positioned(
      right: right,
      left: left,
      top: top,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => onTap([type]),
        child: Container(
          height: height * type.ratios.areaHeightRatio,
          width: actualWidth,
          decoration: BoxDecoration(
            color: selectedTypes != null && selectedTypes?.contains(type) == true
                ? borderColor.withAlpha(70)
                : null,
            borderRadius: BorderRadius.circular(KlimmeckGuideTheme.radius),
            border: Border.all(color: borderColor, width: 4),
          ),
        ),
      ),
    );
  }

  double getActualWidth(double originalWidth) {
    switch (type) {
      case EquipType.gloves:
        return originalWidth / 3.5;
      case EquipType.greaves:
        return originalWidth / 2.1;
      default:
        return originalWidth;
    }
  }
}
