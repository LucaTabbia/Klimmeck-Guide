import 'package:flutter/material.dart';
import 'package:klimmeck_guide/models/equip_ratios.dart';
import 'package:klimmeck_guide/shared/components/cached_svg.dart';

class EquipmentImage extends StatelessWidget {
  const EquipmentImage({
    super.key,
    required this.baseWidth,
    required this.imagePath,
    required this.ratios,
    required this.baseHeight,
  });

  final double baseWidth;
  final double baseHeight;
  final EquipRatios ratios;
  final String imagePath;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left:
          (baseWidth / 2) -
          (baseHeight / ratios.mannequinRatio * ratios.aspectRatio / 2) +
          5,
      top: baseHeight / ratios.positionRatio,
      child: SizedBox(
        height: baseHeight / ratios.mannequinRatio,
        width: baseHeight / ratios.mannequinRatio * ratios.aspectRatio,
        child: CachedSvg(url: imagePath),
      ),
    );
  }
}
