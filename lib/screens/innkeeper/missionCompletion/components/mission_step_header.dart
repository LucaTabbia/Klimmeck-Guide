import 'package:flutter/material.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';

/// «Passo k di 5 · titolo» sopra la pagina del wizard (21-RESEARCH F-4).
class MissionStepHeader extends StatelessWidget {
  const MissionStepHeader({
    super.key,
    required this.stepNumber,
    required this.title,
  });

  static const int stepCount = 5;

  final int stepNumber;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      'Passo $stepNumber di $stepCount · $title',
      style: KlimmeckGuideTheme.instance.titleMedium,
    );
  }
}
