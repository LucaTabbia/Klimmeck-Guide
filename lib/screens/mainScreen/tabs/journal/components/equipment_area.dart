import 'package:flutter/material.dart';
import 'package:klimmeck_guide/models/enums/slot_type.dart';

import '../../../../../theme/kg_theme.dart';

class EquipmentArea extends StatelessWidget {
  const EquipmentArea({
    super.key,
    required this.borderColor,
    required this.onTap,
    required this.baseWidth,
    required this.selectedSlot,
    required this.baseHeight,
    required this.slot,
    this.isRight = false,
  });

  final double baseWidth;
  final double baseHeight;
  final SlotType slot;
  final SlotType? selectedSlot;
  final Color borderColor;
  final bool isRight;
  final Function(SlotType) onTap;

  @override
  Widget build(BuildContext context) {
    final double height = baseHeight / slot.ratios.mannequinRatio;
    final double originalWidth = height * slot.ratios.aspectRatio;
    final actualWidth = getActualWidth(originalWidth);

    final left = isRight
        ? null
        : slot == SlotType.arms
        ? 0.0
        : (baseWidth / 2) - (actualWidth / 2) + 5;
    final right = isRight ? (baseWidth / 2) - (originalWidth / 2) + 4 : null;

    final top =
        baseHeight / slot.ratios.positionRatio +
        baseHeight * slot.ratios.addedTop;

    return Positioned(
      right: right,
      left: left,
      top: top,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => onTap(slot),
        child: Container(
          height: height * slot.ratios.areaHeightRatio,
          width: actualWidth,
          decoration: BoxDecoration(
            color: selectedSlot != null && selectedSlot == slot
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
    switch (slot) {
      case SlotType.arms:
        return originalWidth / 3.5;
      case SlotType.legs:
        return originalWidth / 2.1;
      default:
        return originalWidth;
    }
  }
}
