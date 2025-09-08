import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:klimmeck_guide/models/enums/equip_type.dart';

class EquipmentImage extends StatelessWidget {
  const EquipmentImage({
    super.key,
    required this.baseWidth,
    required this.assetPath,
    required this.type,
    required this.baseHeight,
  });

  final double baseWidth;
  final double baseHeight;
  final EquipType type;
  final String assetPath;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left:
          (baseWidth / 2) -
          (baseHeight / type.ratios.mannequinRatio * type.ratios.aspectRatio / 2) +
          5,
      top: baseHeight / type.ratios.positionRatio,
      child: SizedBox(
        height: baseHeight / type.ratios.mannequinRatio,
        width: baseHeight / type.ratios.mannequinRatio * type.ratios.aspectRatio,
        child: SvgPicture.asset(assetPath),
      ),
    );
  }
}
