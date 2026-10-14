import 'package:flutter/material.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';

/// Riga della scheda: etichetta Cinzel, filetto bronzo, contenuto.
class SheetRow extends StatelessWidget {
  const SheetRow({super.key, required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: KlimmeckGuideTheme.spacingMd),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: KlimmeckGuideTheme.instance.titleMedium),
        const Divider(height: 1, color: KlimmeckGuideTheme.darkBronze),
        const SizedBox(height: KlimmeckGuideTheme.spacingSm),
        child,
      ],
    ),
  );
}
