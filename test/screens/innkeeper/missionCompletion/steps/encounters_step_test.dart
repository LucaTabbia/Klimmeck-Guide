import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/mission/mission_draft.dart';
import 'package:klimmeck_guide/models/mission/mission_enemy.dart';
import 'package:klimmeck_guide/models/mission/mission_limits.dart';
import 'package:klimmeck_guide/models/request/mission_draft_inputs.dart';
import 'package:klimmeck_guide/screens/innkeeper/components/quantity_stepper.dart';
import 'package:klimmeck_guide/screens/innkeeper/missionCompletion/components/enemy_picker.dart';
import 'package:klimmeck_guide/screens/innkeeper/missionCompletion/missionEnemiesCubit/mission_enemies_cubit.dart';
import 'package:klimmeck_guide/screens/innkeeper/missionCompletion/mission_completion_screen.dart';
import 'package:klimmeck_guide/screens/innkeeper/missionCompletion/steps/encounters_step.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/fixtures/mission_fixtures.dart';
import '../../../../helpers/landscape.dart';
import '../../../../helpers/mocks.dart';
import '../../../../helpers/test_app.dart';

final Map<String, dynamic> _goblinJson = missionEnemyJson(
  id: 'enemy-goblin',
  name: 'Goblin',
  xp: 20,
  lifePoints: 60,
);

final MissionEnemy _wolf = MissionEnemy.tryFromJson(missionEnemyJson())!;
final MissionEnemy _goblin = MissionEnemy.tryFromJson(_goblinJson)!;

/// Bestiario servito: lupo, goblin e dieci nemici in più per il tetto delle voci.
final List<MissionEnemy> _served = [
  _wolf,
  _goblin,
  for (var index = 0; index < maxEnemyEntriesPerFight; index++)
    MissionEnemy(id: 'enemy-extra-$index', name: 'Extra $index'),
];

MissionDraft _draftWith(List<Map<String, dynamic>> fights) =>
    MissionDraft.tryFromJson(missionDraftJson(step: 'fights', fights: fights))!;

/// Scontro 1 simulato (lupo x3, vittoria), scontro 2 da simulare (goblin x2).
final MissionDraft _twoFights = _draftWith([
  missionFightJson(verdict: 'success'),
  missionFightJson(
    enemies: [missionFightEnemyJson(enemy: _goblinJson, quantity: 2)],
  ),
]);

final MissionDraft _noFights = _draftWith(const []);

void main() {
  late MockMissionEnemiesCubit enemiesCubit;
  late List<List<List<MissionEnemyInput>>> sent;

  setUp(() {
    enemiesCubit = MockMissionEnemiesCubit();
    sent = [];
    whenListen(
      enemiesCubit,
      const Stream<MissionEnemiesState>.empty(),
      initialState: MissionEnemiesState(enemies: _served),
    );
  });

  Future<void> pumpStep(
    WidgetTester tester,
    MissionDraft draft, {
    bool isSubmitting = false,
  }) async {
    useLandscapePhone(tester);
    await tester.pumpWidget(
      buildTestApp(
        home: Scaffold(
          body: BlocProvider<MissionEnemiesCubit>.value(
            value: enemiesCubit,
            child: EncountersStep(
              draft: draft,
              isSubmitting: isSubmitting,
              onNext: sent.add,
            ),
          ),
        ),
      ),
    );
  }

  Finder card(int index) => find.byKey(EncountersStep.fightCardKeyFor(index));

  Finder inCard(int index, Finder matching) =>
      find.descendant(of: card(index), matching: matching);

  List<QuantityStepper> steppersOf(WidgetTester tester, int index) => tester
      .widgetList<QuantityStepper>(inCard(index, find.byType(QuantityStepper)))
      .toList();

  Future<void> pick(WidgetTester tester, String enemyId) async {
    final row = find.byKey(EnemyPicker.enemyKeyFor(enemyId));
    await tester.scrollUntilVisible(
      row,
      48,
      scrollable: find.descendant(
        of: find.byType(EnemyPicker),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.tap(row);
    await tester.pump();
  }

  Future<void> tapKey(WidgetTester tester, Key key) async {
    await tester.ensureVisible(find.byKey(key));
    await tester.tap(find.byKey(key));
    await tester.pump();
  }

  VoidCallback? onPressedOf(WidgetTester tester, Key key) =>
      tester.widget<ButtonStyleButton>(find.byKey(key)).onPressed;

  testWidgets('starts from the served fights and their picks (D-02, D-09)', (
    tester,
  ) async {
    await pumpStep(tester, _twoFights);

    expect(card(0), findsOneWidget);
    expect(card(1), findsOneWidget);
    expect(inCard(0, find.text(EncountersStep.fightLabel(0))), findsOneWidget);
    expect(inCard(1, find.text(EncountersStep.fightLabel(1))), findsOneWidget);
    final first = steppersOf(tester, 0).single;
    expect((first.label, first.value), ('Lupo', 3));
    final second = steppersOf(tester, 1).single;
    expect((second.label, second.value), ('Goblin', 2));
  });

  testWidgets('a served fight without verdict reads «Da simulare» (D-24)', (
    tester,
  ) async {
    await pumpStep(tester, _twoFights);

    expect(
      inCard(1, find.text(EncountersStep.notSimulatedLabel)),
      findsOneWidget,
    );
  });

  testWidgets('a simulated fight reads «Vittoria» or «Sconfitta» (D-21)', (
    tester,
  ) async {
    await pumpStep(
      tester,
      _draftWith([
        missionFightJson(verdict: 'success'),
        missionFightJson(verdict: 'failure'),
      ]),
    );

    expect(inCard(0, find.text('Vittoria')), findsOneWidget);
    expect(inCard(1, find.text('Sconfitta')), findsOneWidget);
    expect(find.text(EncountersStep.notSimulatedLabel), findsNothing);
  });

  testWidgets('«Aggiungi scontro» adds an empty fight and selects it (D-02)', (
    tester,
  ) async {
    await pumpStep(tester, _twoFights);

    await tapKey(tester, EncountersStep.addFightKey);
    expect(card(2), findsOneWidget);
    expect(inCard(2, find.text(EncountersStep.fightLabel(2))), findsOneWidget);
    expect(
      inCard(2, find.text(EncountersStep.notSimulatedLabel)),
      findsNothing,
    );

    await pick(tester, 'enemy-goblin');

    expect(steppersOf(tester, 2).single.label, 'Goblin');
    expect(steppersOf(tester, 0).single.value, 3);
  });

  testWidgets('«Aggiungi scontro» is disabled at 10 fights (BE cap)', (
    tester,
  ) async {
    await pumpStep(
      tester,
      _draftWith([
        for (var index = 0; index < maxMissionFights - 1; index++)
          missionFightJson(),
      ]),
    );

    expect(onPressedOf(tester, EncountersStep.addFightKey), isNotNull);
    await tapKey(tester, EncountersStep.addFightKey);

    expect(onPressedOf(tester, EncountersStep.addFightKey), isNull);
  });

  testWidgets(
    'picking an enemy adds 1 to the selected fight, again adds 1 more (D-02)',
    (tester) async {
      await pumpStep(tester, _twoFights);

      await pick(tester, 'enemy-goblin');
      expect(
        [
          for (final stepper in steppersOf(tester, 0))
            (stepper.label, stepper.value),
        ],
        [('Lupo', 3), ('Goblin', 1)],
      );

      await pick(tester, 'enemy-goblin');
      expect(steppersOf(tester, 0).last.value, 2);
      expect(steppersOf(tester, 1).single.value, 2);
    },
  );

  testWidgets('tapping a fight selects it for the next pick (D-02)', (
    tester,
  ) async {
    await pumpStep(tester, _twoFights);

    await tester.tap(inCard(1, find.text(EncountersStep.fightLabel(1))));
    await tester.pump();
    await pick(tester, 'enemy-wolf');

    expect(
      [for (final stepper in steppersOf(tester, 1)) stepper.label],
      ['Goblin', 'Lupo'],
    );
    expect(steppersOf(tester, 0).single.value, 3);
  });

  testWidgets('the quantity stops at 20 (BE cap)', (tester) async {
    await pumpStep(
      tester,
      _draftWith([
        missionFightJson(
          enemies: [missionFightEnemyJson(quantity: maxEnemyQuantity)],
        ),
      ]),
    );

    expect(steppersOf(tester, 0).single.max, maxEnemyQuantity);
    await pick(tester, 'enemy-wolf');

    expect(steppersOf(tester, 0).single.value, maxEnemyQuantity);
  });

  testWidgets(
    'a fight with 10 enemy entries takes no new enemy, an enemy already in it still increments (BE cap)',
    (tester) async {
      await pumpStep(
        tester,
        _draftWith([
          missionFightJson(
            enemies: [
              missionFightEnemyJson(quantity: 1),
              for (var index = 1; index < maxEnemyEntriesPerFight; index++)
                missionFightEnemyJson(
                  enemy: missionEnemyJson(
                    id: 'enemy-extra-$index',
                    name: 'Extra $index',
                  ),
                  quantity: 1,
                ),
            ],
          ),
        ]),
      );

      await pick(tester, 'enemy-goblin');
      expect(steppersOf(tester, 0), hasLength(maxEnemyEntriesPerFight));
      expect(
        steppersOf(tester, 0).where((stepper) => stepper.label == 'Goblin'),
        isEmpty,
      );

      await pick(tester, 'enemy-wolf');
      expect(steppersOf(tester, 0).first.value, 2);
    },
  );

  testWidgets('quantity 0 removes the pick (D-02)', (tester) async {
    await pumpStep(
      tester,
      _draftWith([
        missionFightJson(
          enemies: [
            missionFightEnemyJson(quantity: 1),
            missionFightEnemyJson(enemy: _goblinJson, quantity: 2),
          ],
        ),
      ]),
    );

    steppersOf(tester, 0).first.onChanged(0);
    await tester.pump();

    expect(
      [for (final stepper in steppersOf(tester, 0)) stepper.label],
      ['Goblin'],
    );
  });

  testWidgets('«Rimuovi scontro» removes that fight (D-02)', (tester) async {
    await pumpStep(tester, _twoFights);

    await tapKey(tester, EncountersStep.removeFightKeyFor(0));

    expect(card(1), findsNothing);
    expect(steppersOf(tester, 0).single.label, 'Goblin');
    expect(find.text(EncountersStep.removeFightLabel), findsOneWidget);
  });

  testWidgets('«Avanti» sends every fight\'s picks in order (D-02, D-24)', (
    tester,
  ) async {
    await pumpStep(tester, _twoFights);

    await pick(tester, 'enemy-goblin');
    await tapKey(tester, MissionCompletionScreen.nextKey);

    expect(sent, [
      [
        const [
          MissionEnemyInput(enemyId: 'enemy-wolf', quantity: 3),
          MissionEnemyInput(enemyId: 'enemy-goblin', quantity: 1),
        ],
        const [MissionEnemyInput(enemyId: 'enemy-goblin', quantity: 2)],
      ],
    ]);
  });

  testWidgets('zero fights can go on (D-24)', (tester) async {
    await pumpStep(tester, _noFights);

    expect(card(0), findsNothing);
    await tapKey(tester, MissionCompletionScreen.nextKey);

    expect(sent, [const <List<MissionEnemyInput>>[]]);
  });

  testWidgets(
    'a fight without enemies keeps «Avanti» disabled (BE: at least one enemy per fight)',
    (tester) async {
      await pumpStep(tester, _twoFights);

      await tapKey(tester, EncountersStep.addFightKey);

      expect(onPressedOf(tester, MissionCompletionScreen.nextKey), isNull);
    },
  );

  testWidgets('«Avanti» is disabled while a call is in flight', (tester) async {
    await pumpStep(tester, _twoFights, isSubmitting: true);

    expect(onPressedOf(tester, MissionCompletionScreen.nextKey), isNull);
    expect(onPressedOf(tester, EncountersStep.addFightKey), isNull);
  });
}
