import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/models/mission/mission_draft.dart';
import 'package:klimmeck_guide/models/mission/mission_fight.dart';
import 'package:klimmeck_guide/models/quantity_line.dart';
import 'package:klimmeck_guide/models/request/mission_draft_inputs.dart';
import 'package:klimmeck_guide/screens/innkeeper/missionCompletion/components/mission_back_button.dart';
import 'package:klimmeck_guide/screens/innkeeper/missionCompletion/components/correction_section.dart';
import 'package:klimmeck_guide/screens/innkeeper/missionCompletion/missionParticipantsCubit/mission_participants_cubit.dart';
import 'package:klimmeck_guide/screens/innkeeper/missionCompletion/mission_completion_screen.dart';
import 'package:klimmeck_guide/screens/innkeeper/missionCompletion/steps/encounters_step.dart';
import 'package:klimmeck_guide/shared/components/kg_loader.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';

/// Passo «Scontro k di N» (D-04, D-05, D-06, D-24): simulazione del BE, esito
/// del motore e correzioni nei limiti serviti. L'app non calcola vita, ferite,
/// limiti né scadenze (regola 4).
class FightStep extends StatefulWidget {
  const FightStep({
    super.key,
    required this.draft,
    required this.fightIndex,
    required this.isSubmitting,
    required this.onSimulate,
    required this.onChangeEnemies,
    required this.onNext,
  });

  static const String simulateLabel = 'Simula';
  static const String rerunLabel = 'Rilancia';
  static const String changeEnemiesLabel = 'Cambia nemici';
  static const Key simulateKey = ValueKey('mission.fight.simulate');
  static const Key changeEnemiesKey = ValueKey('mission.fight.changeEnemies');

  final MissionDraft draft;
  final int fightIndex;
  final bool isSubmitting;
  final VoidCallback onSimulate;
  final VoidCallback onChangeEnemies;
  final void Function(List<MissionCorrection> corrections) onNext;

  @override
  State<FightStep> createState() => _FightStepState();
}

class _FightStepState extends State<FightStep> {
  static const double _loaderSize = 32;

  Map<String, MissionCorrection> _corrections = const {};

  MissionFight? get _fight =>
      widget.draft.fights.elementAtOrNull(widget.fightIndex);

  @override
  void initState() {
    super.initState();
    _corrections = _seededFrom(_fight);
  }

  /// D-09: una nuova bozza servita per questo scontro riparte dai suoi effetti.
  @override
  void didUpdateWidget(FightStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    final previous = oldWidget.draft.fights.elementAtOrNull(
      oldWidget.fightIndex,
    );
    if (previous == _fight) return;
    _corrections = _seededFrom(_fight);
  }

  static Map<String, MissionCorrection> _seededFrom(MissionFight? fight) => {
    for (final outcome in fight?.outcomes ?? const <MissionFightOutcome>[])
      if (outcome.effective case final effective?)
        outcome.characterId: MissionCorrection.fromEffects(
          outcome.characterId,
          effective,
        ),
  };

  /// D-24: lo scontro k si simula solo dopo il k-1 servito simulato.
  bool get _canSimulate {
    if (widget.isSubmitting) return false;
    if (widget.fightIndex == 0) return true;
    return widget.draft.fights[widget.fightIndex - 1].isSimulated;
  }

  /// Sempre la lista completa, una per partecipante con `hpAfter` (BE handoff).
  List<MissionCorrection> get _orderedCorrections => [
    for (final participant in widget.draft.participants)
      ?_corrections[participant.characterId],
  ];

  void _correct(MissionCorrection correction) => setState(
    () => _corrections = {..._corrections, correction.characterId: correction},
  );

  @override
  Widget build(BuildContext context) {
    final fight = _fight;
    if (fight == null) return const SizedBox.shrink();
    final theme = KlimmeckGuideTheme.instance;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: _details(fight, theme)),
        _actions(fight, theme),
      ],
    );
  }

  Widget _actions(MissionFight fight, KlimmeckGuideTheme theme) {
    return Wrap(
      spacing: KlimmeckGuideTheme.spacingSm,
      runSpacing: KlimmeckGuideTheme.spacingXs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        const MissionBackButton(),
        Text(
          fight.verdict?.label ?? EncountersStep.notSimulatedLabel,
          style: theme.titleMedium,
        ),
        if (widget.isSubmitting)
          const KGLoader(width: _loaderSize, height: _loaderSize),
        ElevatedButton(
          key: FightStep.simulateKey,
          style: KlimmeckGuideTheme.primaryButtonStyle,
          onPressed: _canSimulate ? widget.onSimulate : null,
          child: Text(
            fight.isSimulated ? FightStep.rerunLabel : FightStep.simulateLabel,
          ),
        ),
        TextButton(
          key: FightStep.changeEnemiesKey,
          onPressed: widget.isSubmitting ? null : widget.onChangeEnemies,
          child: const Text(FightStep.changeEnemiesLabel),
        ),
        ElevatedButton(
          key: MissionCompletionScreen.nextKey,
          style: KlimmeckGuideTheme.primaryButtonStyle,
          onPressed: fight.isSimulated && !widget.isSubmitting
              ? () => widget.onNext(_orderedCorrections)
              : null,
          child: const Text(MissionCompletionScreen.nextLabel),
        ),
      ],
    );
  }

  /// I nemici in testa, poi una sezione per partecipante con un esito
  /// effettivo servito (nessuna prima della simulazione, D-24).
  Widget _details(MissionFight fight, KlimmeckGuideTheme theme) {
    final sections = [
      if (fight.isSimulated)
        for (final participant in widget.draft.participants)
          if ((
                fight.outcomeOf(participant.characterId),
                _corrections[participant.characterId],
              )
              case (final outcome?, final correction?))
            (
              participant: participant,
              outcome: outcome,
              correction: correction,
            ),
    ];
    final enemiesLine = Text(
      fight.enemies
          .map((entry) => quantityLine(entry.quantity, entry.enemy.name))
          .join(', '),
      style: theme.bodyMedium,
    );
    return BlocBuilder<MissionParticipantsCubit, MissionParticipantsState>(
      builder: (context, participants) {
        final loaded = participants is MissionParticipantsLoaded
            ? participants
            : null;
        return ListView.builder(
          itemCount: sections.length + 1,
          itemBuilder: (_, index) {
            if (index == 0) return enemiesLine;
            final section = sections[index - 1];
            final characterId = section.participant.characterId;
            return Padding(
              padding: const EdgeInsets.only(top: KlimmeckGuideTheme.spacingMd),
              child: CorrectionSection(
                participant: section.participant,
                outcome: section.outcome,
                correction: section.correction,
                itemNameOf: (itemId) => loaded?.itemNameOf(characterId, itemId),
                spellNameOf: (spellId) =>
                    loaded?.spellNameOf(characterId, spellId),
                onChanged: _correct,
              ),
            );
          },
        );
      },
    );
  }
}
