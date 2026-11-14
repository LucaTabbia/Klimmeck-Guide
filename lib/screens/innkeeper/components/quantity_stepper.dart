import 'package:flutter/material.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';

/// Quantità limitata `min..max` con «−» e «+» (10-CONTEXT D-12): il limite
/// rispecchia quello del BE, che resta giudice.
class QuantityStepper extends StatelessWidget {
  const QuantityStepper({
    super.key,
    required this.label,
    required this.value,
    required this.max,
    required this.onChanged,
    this.min = 0,
  });

  final String label;
  final int value;
  final int max;

  /// Limite basso, 0 di default; 1 per i premi (D-15).
  final int min;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = KlimmeckGuideTheme.instance;
    return Row(
      children: [
        Expanded(child: Text(label, style: theme.bodyMedium)),
        IconButton(
          tooltip: 'Diminuisci',
          icon: const Icon(Icons.remove),
          onPressed: value > min ? () => onChanged(value - 1) : null,
        ),
        Text('$value / $max', style: theme.bodyMedium),
        IconButton(
          tooltip: 'Aumenta',
          icon: const Icon(Icons.add),
          onPressed: value < max ? () => onChanged(value + 1) : null,
        ),
      ],
    );
  }
}
