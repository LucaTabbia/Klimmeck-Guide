import 'package:flutter/material.dart';
import 'package:klimmeck_guide/models/enums/injury_type.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';

/// Ferite di una correzione in due gruppi (Phase 24 D-13, D-16): quelle
/// portate all'inizio dello scontro, tenute o tolte, e quelle da aggiungere.
/// Una ferita portata e non tolta non si aggiunge; tolta, torna aggiungibile.
/// Il segno dell'oste viene solo dalle liste servite (regola 4). Senza
/// [onRemovalToggled] le ferite portate non si toccano.
class InjuryChips extends StatelessWidget {
  const InjuryChips({
    super.key,
    required this.carried,
    required this.innkeeperCarried,
    required this.removed,
    required this.added,
    required this.innkeeperAdded,
    required this.onRemovalToggled,
    required this.onAddToggled,
  });

  static const String carriedHeading = 'Ferite presenti';
  static const String addedHeading = 'Ferite da aggiungere';
  static const String innkeeperNote =
      'Una ferita aggiunta a mano è dell\'oste: nessuna cura la toglie';
  static const Key innkeeperNoteKey = ValueKey(
    'completion.injury.innkeeperNote',
  );

  static String innkeeperLabelOf(InjuryType injury) =>
      '${injury.label} (dell\'oste)';
  static Key keptKeyOf(InjuryType injury) =>
      ValueKey('completion.injury.kept.${injury.name}');
  static Key addedKeyOf(InjuryType injury) =>
      ValueKey('completion.injury.added.${injury.name}');

  final List<InjuryType> carried;
  final List<InjuryType> innkeeperCarried;
  final List<InjuryType> removed;
  final List<InjuryType> added;
  final List<InjuryType> innkeeperAdded;

  /// `null` = le ferite portate non si tolgono.
  final ValueChanged<InjuryType>? onRemovalToggled;
  final ValueChanged<InjuryType> onAddToggled;

  bool _isKept(InjuryType injury) =>
      carried.contains(injury) && !removed.contains(injury);

  bool _isInnkeeperAdded(InjuryType injury) =>
      added.contains(injury) && innkeeperAdded.contains(injury);

  @override
  Widget build(BuildContext context) {
    final onRemovalToggled = this.onRemovalToggled;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (carried.isNotEmpty)
          _Group(
            heading: carriedHeading,
            chips: [
              for (final injury in carried)
                FilterChip(
                  key: keptKeyOf(injury),
                  label: Text(
                    _labelOf(injury, innkeeperCarried.contains(injury)),
                  ),
                  selected: !removed.contains(injury),
                  onSelected: onRemovalToggled == null
                      ? null
                      : (_) => onRemovalToggled(injury),
                ),
            ],
          ),
        _Group(
          heading: addedHeading,
          chips: [
            for (final injury in InjuryType.values)
              FilterChip(
                key: addedKeyOf(injury),
                label: Text(_labelOf(injury, _isInnkeeperAdded(injury))),
                selected: added.contains(injury),
                onSelected: _isKept(injury)
                    ? null
                    : (_) => onAddToggled(injury),
              ),
          ],
        ),
        if (onRemovalToggled != null)
          Padding(
            padding: const EdgeInsets.only(top: KlimmeckGuideTheme.spacingXs),
            child: Text(
              innkeeperNote,
              key: innkeeperNoteKey,
              style: KlimmeckGuideTheme.instance.bodyMedium,
            ),
          ),
      ],
    );
  }

  static String _labelOf(InjuryType injury, bool isInnkeepers) =>
      isInnkeepers ? innkeeperLabelOf(injury) : injury.label;
}

class _Group extends StatelessWidget {
  const _Group({required this.heading, required this.chips});

  final String heading;
  final List<Widget> chips;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            vertical: KlimmeckGuideTheme.spacingXs,
          ),
          child: Text(heading, style: KlimmeckGuideTheme.instance.bodyMedium),
        ),
        Wrap(
          spacing: KlimmeckGuideTheme.spacingXs,
          runSpacing: KlimmeckGuideTheme.spacingXs,
          children: chips,
        ),
      ],
    );
  }
}
