import 'package:flutter/material.dart';
import 'package:klimmeck_guide/models/enums/injury_type.dart';
import 'package:klimmeck_guide/models/request/participant_draft.dart';
import 'package:klimmeck_guide/screens/innkeeper/components/injury_chips.dart';
import 'package:klimmeck_guide/screens/innkeeper/components/quantity_stepper.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';

/// Sezione del form per un partecipante (10-CONTEXT D-12, ADMIN-05/06): PV,
/// ferite, consumabili e magie, ognuno nei limiti del BE.
class ParticipantOverrideSection extends StatelessWidget {
  const ParticipantOverrideSection({
    super.key,
    required this.draft,
    required this.onHpChanged,
    required this.onInjuryToggled,
    required this.onConsumableChanged,
    required this.onSpellChanged,
  });

  static Key hpSliderKey(String characterId) =>
      ValueKey('completion.hp.$characterId');

  static const String _unnamedItem = 'Oggetto';
  static const String _unnamedSpell = 'Magia sconosciuta';

  final ParticipantDraft draft;
  final ValueChanged<int> onHpChanged;
  final ValueChanged<InjuryType> onInjuryToggled;
  final void Function(String itemId, int quantity) onConsumableChanged;
  final void Function(String spellId, int usages) onSpellChanged;

  @override
  Widget build(BuildContext context) {
    final theme = KlimmeckGuideTheme.instance;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(draft.name, style: theme.titleMedium),
        const _Heading('Punti vita'),
        if (draft.canEditHp)
          Slider(
            key: hpSliderKey(draft.characterId),
            min: 1,
            max: draft.maxLifePoints.toDouble(),
            divisions: draft.maxLifePoints - 1,
            value: draft.hpAfter.toDouble(),
            label: '${draft.hpAfter}',
            onChanged: (value) => onHpChanged(value.round()),
          ),
        Text(
          '${draft.hpAfter} / ${draft.maxLifePoints}',
          style: theme.bodyMedium,
        ),
        const _Heading('Ferite'),
        InjuryChips(
          existing: draft.existingInjuries,
          added: draft.addedInjuries,
          onToggled: onInjuryToggled,
        ),
        const _Heading('Consumabili'),
        if (draft.consumables.isEmpty)
          Text('Nessun consumabile', style: theme.bodyMedium),
        for (final line in draft.consumables)
          QuantityStepper(
            key: ValueKey(
              'completion.consumable.${draft.characterId}.${line.itemId}',
            ),
            label: line.name ?? _unnamedItem,
            value: line.used,
            max: line.owned,
            onChanged: (quantity) => onConsumableChanged(line.itemId, quantity),
          ),
        const _Heading('Magie'),
        if (draft.spells.isEmpty)
          Text('Nessuna magia attiva', style: theme.bodyMedium),
        for (final line in draft.spells)
          QuantityStepper(
            key: ValueKey(
              'completion.spell.${draft.characterId}.${line.spellId}',
            ),
            label: line.name ?? _unnamedSpell,
            value: line.used,
            max: line.remaining,
            onChanged: (usages) => onSpellChanged(line.spellId, usages),
          ),
      ],
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: KlimmeckGuideTheme.spacingMd),
      child: Text(text, style: KlimmeckGuideTheme.instance.bodyLarge),
    );
  }
}
