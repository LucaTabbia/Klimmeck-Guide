import 'package:flutter/material.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';

/// «Genera missioni» in cima alla Locanda (D-08): sempre visibile, anche a
/// coda vuota o in caricamento; disabilitato mentre la corsa è in volo (D-09).
class GenerateQuestsButton extends StatelessWidget {
  const GenerateQuestsButton({
    super.key,
    required this.isSubmitting,
    required this.onPressed,
  });

  static const Key buttonKey = ValueKey('innkeeper.generateQuests');
  static const String label = 'Genera missioni';

  final bool isSubmitting;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => ElevatedButton(
    key: buttonKey,
    style: KlimmeckGuideTheme.primaryButtonStyle,
    onPressed: isSubmitting ? null : onPressed,
    child: const Text(label),
  );
}
