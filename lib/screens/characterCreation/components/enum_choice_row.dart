import 'package:flutter/material.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';

/// Scelta di un valore enum tramite chip; nessuna preselezione (D-13).
class EnumChoiceRow<T extends Enum> extends StatelessWidget {
  const EnumChoiceRow({
    super.key,
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onSelected,
    this.enabled = true,
  });

  final List<T> values;
  final T? selected;
  final String Function(T) labelOf;
  final ValueChanged<T> onSelected;
  final bool enabled;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: KlimmeckGuideTheme.spacingSm,
    runSpacing: KlimmeckGuideTheme.spacingSm,
    children: [
      for (final value in values)
        ChoiceChip(
          label: Text(labelOf(value)),
          selected: value == selected,
          materialTapTargetSize: MaterialTapTargetSize.padded,
          onSelected: enabled ? (_) => onSelected(value) : null,
        ),
    ],
  );
}
