import 'package:flutter/material.dart';
import 'package:klimmeck_guide/models/enums/injury_type.dart';
import 'package:klimmeck_guide/shared/components/cached_svg.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';

class InjuryNameIcon extends StatelessWidget {
  const InjuryNameIcon({super.key, required this.injury});

  final InjuryType injury;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          ...List.generate(injury.effects.length, (index) {
            return CachedSvg(url: injury.effects[index].imagePath, height: 50, width: 50);
          }),
          Padding(
            padding: const EdgeInsets.only(left: 15.0),
            child: Text(injury.label, style: KlimmeckGuideTheme.instance.bodyMedium),
          ),
        ],
      ),
    );
  }
}
