import 'package:flutter/material.dart';
import 'package:klimmeck_guide/models/enums/equip_type.dart';
import 'package:klimmeck_guide/models/equipment_item.dart';
import 'package:klimmeck_guide/shared/components/cached_svg.dart';

import '../../../../../theme/kg_theme.dart';

class EquipmentBox extends StatelessWidget {
  const EquipmentBox({
    super.key,
    required this.size,
    required this.item,
    required this.selectedBox,
    required this.index,
    required this.expectedTypes,
    required this.onTap,
  });

  final double size;
  final EquipmentItem? item;
  final List<EquipType> expectedTypes;
  final int? selectedBox;
  final int index;
  final Function(int, List<EquipType>) onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(index, expectedTypes),
      child: Container(
        height: size,
        width: size,
        decoration: BoxDecoration(
          color: index == selectedBox ? KlimmeckGuideTheme.primaryGold.withAlpha(100) : null,
          borderRadius: BorderRadius.circular(KlimmeckGuideTheme.radius),
          border: Border.all(color: KlimmeckGuideTheme.deepNight, width: 2),
        ),
        child: item != null ? CachedSvg(url: item!.equipType!.imagePath) : null,
      ),
    );
  }
}
