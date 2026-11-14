import 'package:flutter/material.dart';
import 'package:klimmeck_guide/models/mission/mission_draft.dart';
import 'package:klimmeck_guide/models/mission/mission_enemy.dart';
import 'package:klimmeck_guide/models/mission/mission_limits.dart';
import 'package:klimmeck_guide/models/request/mission_draft_inputs.dart';
import 'package:klimmeck_guide/screens/innkeeper/components/quantity_stepper.dart';
import 'package:klimmeck_guide/screens/innkeeper/missionCompletion/components/enemy_picker.dart';
import 'package:klimmeck_guide/screens/innkeeper/missionCompletion/mission_completion_screen.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';

typedef _EnemyPick = ({MissionEnemy enemy, int quantity});

/// Scontro in modifica: [servedIndex] è lo scontro servito da cui viene
/// (`null` per uno nuovo), così lo stato resta suo anche se la lista cambia.
typedef _LocalFight = ({int? servedIndex, List<_EnemyPick> picks});

/// Passo «Scontri» (D-02, D-03, D-24): zero, uno o più scontri, ognuno coi
/// nemici della lista servita e le loro quantità. I tetti di
/// `mission_limits.dart` sono solo limiti di UI: il BE resta giudice.
class EncountersStep extends StatefulWidget {
  const EncountersStep({
    super.key,
    required this.draft,
    required this.isSubmitting,
    required this.onNext,
  });

  static const String addFightLabel = 'Aggiungi scontro';
  static const String removeFightLabel = 'Rimuovi scontro';
  static const String notSimulatedLabel = 'Da simulare';
  static String fightLabel(int index) => 'Scontro ${index + 1}';
  static const Key addFightKey = ValueKey('mission.fights.add');
  static Key removeFightKeyFor(int index) =>
      ValueKey('mission.fights.remove.$index');
  static Key fightCardKeyFor(int index) =>
      ValueKey('mission.fights.card.$index');

  final MissionDraft draft;
  final bool isSubmitting;
  final void Function(List<List<MissionEnemyInput>> enemiesPerFight) onNext;

  @override
  State<EncountersStep> createState() => _EncountersStepState();
}

class _EncountersStepState extends State<EncountersStep> {
  late List<_LocalFight> _fights;
  int? _selected;

  @override
  void initState() {
    super.initState();
    _fights = [
      for (final (index, fight) in widget.draft.fights.indexed)
        (
          servedIndex: index,
          picks: [
            for (final served in fight.enemies)
              (enemy: served.enemy, quantity: served.quantity),
          ],
        ),
    ];
    _selected = _fights.isEmpty ? null : 0;
  }

  bool get _canAddFight =>
      !widget.isSubmitting && _fights.length < maxMissionFights;

  /// Il BE rifiuta uno scontro senza nemici: «Avanti» aspetta che ognuno ne abbia.
  bool get _canGoOn =>
      !widget.isSubmitting && _fights.every((fight) => fight.picks.isNotEmpty);

  void _addFight() => setState(() {
    _fights = [..._fights, (servedIndex: null, picks: const [])];
    _selected = _fights.length - 1;
  });

  void _removeFight(int index) => setState(() {
    _fights = [..._fights]..removeAt(index);
    _selected = _selectionAfterRemoving(index);
  });

  int? _selectionAfterRemoving(int removed) {
    final selected = _selected;
    if (_fights.isEmpty || selected == null) return null;
    if (selected > removed) return selected - 1;
    return selected.clamp(0, _fights.length - 1);
  }

  void _select(int index) => setState(() => _selected = index);

  void _pick(MissionEnemy enemy) {
    final index = _selected;
    if (index == null) return;
    final picks = _fights[index].picks;
    final at = picks.indexWhere((pick) => pick.enemy.id == enemy.id);
    if (at >= 0) return _setQuantity(index, at, picks[at].quantity + 1);
    if (picks.length >= maxEnemyEntriesPerFight) return;
    _replaceFight(index, [
      ...picks,
      (enemy: enemy, quantity: minEnemyQuantity),
    ]);
  }

  void _setQuantity(int fightIndex, int pickIndex, int quantity) {
    if (quantity > maxEnemyQuantity) return;
    final picks = [..._fights[fightIndex].picks];
    if (quantity <= 0) {
      picks.removeAt(pickIndex);
    } else {
      picks[pickIndex] = (enemy: picks[pickIndex].enemy, quantity: quantity);
    }
    _replaceFight(fightIndex, picks);
  }

  void _replaceFight(int index, List<_EnemyPick> picks) => setState(
    () =>
        _fights = [..._fights]
          ..[index] = (servedIndex: _fights[index].servedIndex, picks: picks),
  );

  void _goOn() => widget.onNext([
    for (final fight in _fights)
      [
        for (final pick in fight.picks)
          if (pick.quantity > 0)
            MissionEnemyInput(enemyId: pick.enemy.id, quantity: pick.quantity),
      ],
  ]);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var index = 0; index < _fights.length; index++)
                        _fightCard(index),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: KlimmeckGuideTheme.spacingSm),
              Expanded(child: EnemyPicker(onPick: _pick)),
            ],
          ),
        ),
        Row(
          children: [
            TextButton(
              key: EncountersStep.addFightKey,
              onPressed: _canAddFight ? _addFight : null,
              child: const Text(EncountersStep.addFightLabel),
            ),
            const Spacer(),
            ElevatedButton(
              key: MissionCompletionScreen.nextKey,
              style: KlimmeckGuideTheme.primaryButtonStyle,
              onPressed: _canGoOn ? _goOn : null,
              child: const Text(MissionCompletionScreen.nextLabel),
            ),
          ],
        ),
      ],
    );
  }

  Widget _fightCard(int index) {
    final theme = KlimmeckGuideTheme.instance;
    final status = _statusOf(index);
    return Card(
      key: EncountersStep.fightCardKeyFor(index),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(KlimmeckGuideTheme.spacingSm),
        side: BorderSide(
          color: index == _selected
              ? KlimmeckGuideTheme.darkBronze
              : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () => _select(index),
        child: Padding(
          padding: const EdgeInsets.all(KlimmeckGuideTheme.spacingSm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      EncountersStep.fightLabel(index),
                      style: theme.titleMedium,
                    ),
                  ),
                  if (status != null) Text(status, style: theme.bodyMedium),
                ],
              ),
              for (final (pickIndex, pick) in _fights[index].picks.indexed)
                QuantityStepper(
                  label: pick.enemy.name,
                  value: pick.quantity,
                  max: maxEnemyQuantity,
                  onChanged: (quantity) =>
                      _setQuantity(index, pickIndex, quantity),
                ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  key: EncountersStep.removeFightKeyFor(index),
                  onPressed: widget.isSubmitting
                      ? null
                      : () => _removeFight(index),
                  child: const Text(EncountersStep.removeFightLabel),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Solo dallo scontro servito da cui viene la carta (D-21, D-24): l'app
  /// non decide se è scaduto; uno scontro nuovo non ha stato.
  String? _statusOf(int index) {
    final servedIndex = _fights[index].servedIndex;
    final served = widget.draft.fights;
    if (servedIndex == null || servedIndex >= served.length) return null;
    return served[servedIndex].verdict?.label ??
        EncountersStep.notSimulatedLabel;
  }
}
