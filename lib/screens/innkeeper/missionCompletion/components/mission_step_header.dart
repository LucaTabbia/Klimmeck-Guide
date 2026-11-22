import 'package:flutter/material.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';

/// «Passo k di N · titolo» sopra la pagina del wizard (21-RESEARCH F-4): il
/// conto delle pagine lo dà la schermata.
class MissionStepHeader extends StatelessWidget {
  const MissionStepHeader({
    super.key,
    required this.stepNumber,
    required this.stepCount,
    required this.title,
  });

  final int stepNumber;
  final int stepCount;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      'Passo $stepNumber di $stepCount · $title',
      style: KlimmeckGuideTheme.instance.titleMedium,
    );
  }
}
