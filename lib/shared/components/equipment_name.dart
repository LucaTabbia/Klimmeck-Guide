import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:klimmeck_guide/models/equipment_item.dart';
import 'package:klimmeck_guide/shared/components/cached_svg.dart';

import '../../theme/kg_theme.dart';

class EquipmentName extends StatelessWidget {
  const EquipmentName({super.key, required this.equipmentItem, required this.height});

  final EquipmentItem equipmentItem;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          height: height,
          width: height,
          child: CachedSvg(url: equipmentItem.equipType!.imagePath),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 10.0),
          child: AutoSizeText(
            maxFontSize: 24,
            minFontSize: 20,
            equipmentItem.name?.toString() ?? "",
            style: KlimmeckGuideTheme.instance.bodyLarge.copyWith(
              color: equipmentItem.rarity!.color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}
