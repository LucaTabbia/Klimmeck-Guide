import 'package:flutter/material.dart';
import 'package:klimmeck_guide/models/enums/injury_type.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';

/// Ferite come chip (10-CONTEXT D-12, ADMIN-06): quelle già presenti sono inattive, l'override porta solo le aggiunte.
class InjuryChips extends StatelessWidget {
  const InjuryChips({
    super.key,
    required this.existing,
    required this.added,
    required this.onToggled,
  });

  final List<InjuryType> existing;
  final List<InjuryType> added;
  final ValueChanged<InjuryType> onToggled;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: KlimmeckGuideTheme.spacingXs,
      runSpacing: KlimmeckGuideTheme.spacingXs,
      children: [
        for (final injury in InjuryType.values)
          FilterChip(
            key: ValueKey('completion.injury.${injury.name}'),
            label: Text(injury.label),
            selected: existing.contains(injury) || added.contains(injury),
            onSelected: existing.contains(injury)
                ? null
                : (_) => onToggled(injury),
          ),
      ],
    );
  }
}
