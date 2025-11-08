import 'package:flutter/material.dart';
import 'package:klimmeck_guide/models/enums/slot_type.dart';
import 'package:klimmeck_guide/models/equipment_item.dart';
import 'package:klimmeck_guide/shared/components/cached_svg.dart';

import '../../../../../theme/kg_theme.dart';

class EquipmentBox extends StatelessWidget {
  const EquipmentBox({
    super.key,
    required this.size,
    required this.item,
    required this.selectedBox,
    required this.slotType,
    required this.onTap,
  });

  final double size;
  final EquipmentItem? item;
  final SlotType? selectedBox;
  final SlotType slotType;
  final Function(SlotType) onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(slotType),
      child: Container(
        height: size,
        width: size,
        decoration: BoxDecoration(
          color: slotType == selectedBox
              ? KlimmeckGuideTheme.primaryGold.withAlpha(100)
              : null,
          borderRadius: BorderRadius.circular(KlimmeckGuideTheme.radius),
          border: Border.all(color: KlimmeckGuideTheme.deepNight, width: 2),
        ),
        child: item != null ? CachedSvg(url: item!.equipType!.imagePath) : null,
      ),
    );
  }
}
