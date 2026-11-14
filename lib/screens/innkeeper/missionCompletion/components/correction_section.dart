import 'package:flutter/material.dart';
import 'package:klimmeck_guide/models/mission/mission_draft.dart';
import 'package:klimmeck_guide/models/mission/mission_fight.dart';
import 'package:klimmeck_guide/models/mission/mission_limits.dart';
import 'package:klimmeck_guide/models/request/mission_draft_inputs.dart';
import 'package:klimmeck_guide/screens/innkeeper/components/injury_chips.dart';
import 'package:klimmeck_guide/screens/innkeeper/components/quantity_stepper.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';

/// Correzioni di un personaggio dopo uno scontro simulato (D-06, D-14): ogni
/// limite viene dalla bozza servita (regola 4). Le ferite in
/// `outcome.injuriesBefore` sono bloccate per scontro, come sul BE: quelle
/// aggiunte dallo scontro precedente si tolgono correggendo quello.
class CorrectionSection extends StatelessWidget {
  const CorrectionSection({
    super.key,
    required this.participant,
    required this.outcome,
    required this.correction,
    required this.itemNameOf,
    required this.spellNameOf,
    required this.onChanged,
  });

  static Key headerKeyFor(String characterId) =>
      ValueKey('mission.correction.header.$characterId');
  static Key hpSliderKeyFor(String characterId) =>
      ValueKey('mission.correction.hp.$characterId');

  final MissionParticipant participant;
  final MissionFightOutcome outcome;
  final MissionCorrection correction;
  final String? Function(String itemId) itemNameOf;
  final String? Function(String spellId) spellNameOf;
  final ValueChanged<MissionCorrection> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = KlimmeckGuideTheme.instance;
    final simulated = outcome.simulated;
    return ExpansionTile(
      key: ValueKey('mission.correction.tile.${participant.characterId}'),
      maintainState: true,
      tilePadding: EdgeInsets.zero,
      shape: const Border(),
      collapsedShape: const Border(),
      expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
      title: Text(
        '${participant.name} · PV ${outcome.hpBefore} → ${correction.hpAfter}',
        key: headerKeyFor(participant.characterId),
        style: theme.titleMedium,
      ),
      children: [
        if (simulated != null)
          Text(
            'PV ${outcome.hpBefore} → ${simulated.hpAfter}',
            style: theme.bodyMedium,
          ),
        const _Heading('Punti vita'),
        ..._lifePoints(theme),
        const _Heading('Ferite'),
        InjuryChips(
          existing: outcome.injuriesBefore,
          added: correction.injuries,
          onToggled: (injury) =>
              onChanged(correction.withInjuryToggled(injury)),
        ),
        const _Heading('Consumabili'),
        if (outcome.consumablesAvailable.isEmpty)
          Text('Nessun consumabile', style: theme.bodyMedium),
        for (final available in outcome.consumablesAvailable)
          QuantityStepper(
            label: itemNameOf(available.itemId) ?? available.itemId,
            value: correction.consumablesUsed[available.itemId] ?? 0,
            max: available.quantity,
            onChanged: (quantity) => onChanged(
              correction.withConsumableUsed(available.itemId, quantity),
            ),
          ),
        const _Heading('Magie'),
        if (outcome.spellsAvailable.isEmpty)
          Text('Nessuna magia attiva', style: theme.bodyMedium),
        for (final available in outcome.spellsAvailable)
          QuantityStepper(
            label: spellNameOf(available.spellId) ?? available.spellId,
            value: correction.spellsUsed[available.spellId] ?? 0,
            max: available.usages,
            onChanged: (usages) =>
                onChanged(correction.withSpellUsed(available.spellId, usages)),
          ),
      ],
    );
  }

  /// Pitfall 9: con un solo punto vita lo slider non ha divisioni, resta il testo.
  List<Widget> _lifePoints(KlimmeckGuideTheme theme) {
    final max = participant.maxLifePoints;
    return [
      if (max > minLifeAfterFight)
        Slider(
          key: hpSliderKeyFor(participant.characterId),
          min: minLifeAfterFight.toDouble(),
          max: max.toDouble(),
          divisions: max - minLifeAfterFight,
          value: correction.hpAfter.clamp(minLifeAfterFight, max).toDouble(),
          label: '${correction.hpAfter}',
          onChanged: (value) => onChanged(correction.withHp(value.round())),
        ),
      Text('${correction.hpAfter} / $max', style: theme.bodyMedium),
    ];
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
