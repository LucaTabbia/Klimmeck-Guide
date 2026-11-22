import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/enums/injury_type.dart';
import 'package:klimmeck_guide/models/mission/mission_draft.dart';
import 'package:klimmeck_guide/models/request/mission_draft_inputs.dart';
import 'package:klimmeck_guide/screens/innkeeper/components/injury_chips.dart';
import 'package:klimmeck_guide/screens/innkeeper/missionCompletion/components/correction_section.dart';
import 'package:klimmeck_guide/screens/innkeeper/missionCompletion/missionParticipantsCubit/mission_participants_cubit.dart';
import 'package:klimmeck_guide/screens/innkeeper/missionCompletion/mission_completion_screen.dart';
import 'package:klimmeck_guide/screens/innkeeper/missionCompletion/steps/encounters_step.dart';
import 'package:klimmeck_guide/screens/innkeeper/missionCompletion/steps/fight_step.dart';

import '../../../../helpers/fixtures/mission_fixtures.dart';
import '../../../../helpers/landscape.dart';
import '../../../../helpers/mocks.dart';
import '../../../../helpers/test_app.dart';

const String _aldo = 'char-aldo';
const String _bea = 'char-bea';

final List<Map<String, dynamic>> _participants = [
  missionParticipantJson(),
  missionParticipantJson(
    character: _bea,
    name: 'Bea',
    pendingQuest: 'pq-world-2',
  ),
];

/// Esiti serviti di Aldo e Bea: simulati con [aldoHp] / 750 oppure da simulare.
List<Map<String, dynamic>> _outcomes({
  bool simulated = true,
  int aldoHp = 700,
  Map<String, dynamic>? aldoCorrected,
}) => [
  missionOutcomeJson(
    simulated: simulated ? missionEffectsJson(hpAfter: aldoHp) : null,
    corrected: aldoCorrected,
  ),
  missionOutcomeJson(
    character: _bea,
    injuriesBefore: const [],
    simulated: simulated
        ? missionEffectsJson(hpAfter: 750, injuriesAdded: const [])
        : null,
  ),
];

MissionDraft _draft({
  String? first,
  String? second,
  int aldoHp = 700,
  Map<String, dynamic>? aldoCorrected,
}) => MissionDraft.tryFromJson(
  missionDraftJson(
    step: 'fights',
    participants: _participants,
    fights: [
      missionFightJson(
        verdict: first,
        outcomes: _outcomes(
          simulated: first != null,
          aldoHp: aldoHp,
          aldoCorrected: aldoCorrected,
        ),
      ),
      missionFightJson(
        enemies: [
          missionFightEnemyJson(
            enemy: missionEnemyJson(id: 'enemy-goblin', name: 'Goblin'),
            quantity: 2,
          ),
        ],
        verdict: second,
        outcomes: _outcomes(simulated: second != null),
      ),
    ],
  ),
)!;

void main() {
  late MockMissionParticipantsCubit participantsCubit;
  late int simulations;
  late int enemyChanges;
  late List<List<MissionCorrection>> sent;

  setUp(() {
    participantsCubit = MockMissionParticipantsCubit();
    simulations = 0;
    enemyChanges = 0;
    sent = [];
    whenListen(
      participantsCubit,
      const Stream<MissionParticipantsState>.empty(),
      initialState: const MissionParticipantsIdle(),
    );
  });

  Future<void> pumpStep(
    WidgetTester tester,
    MissionDraft draft, {
    int fightIndex = 0,
    bool isSubmitting = false,
    bool isWoundRemovalEnabled = false,
  }) async {
    useLandscapePhone(tester);
    await tester.pumpWidget(
      buildTestApp(
        home: Scaffold(
          body: BlocProvider<MissionParticipantsCubit>.value(
            value: participantsCubit,
            child: FightStep(
              draft: draft,
              fightIndex: fightIndex,
              isSubmitting: isSubmitting,
              onSimulate: () => simulations++,
              onChangeEnemies: () => enemyChanges++,
              onNext: sent.add,
              isWoundRemovalEnabled: isWoundRemovalEnabled,
            ),
          ),
        ),
      ),
    );
  }

  VoidCallback? onPressedOf(WidgetTester tester, Key key) =>
      tester.widget<ButtonStyleButton>(find.byKey(key)).onPressed;

  CorrectionSection sectionOf(WidgetTester tester, String characterId) => tester
      .widgetList<CorrectionSection>(find.byType(CorrectionSection))
      .firstWhere((section) => section.participant.characterId == characterId);

  testWidgets(
    '«Simula» is disabled until the previous fight is simulated (D-24)',
    (tester) async {
      await pumpStep(tester, _draft(), fightIndex: 1);
      expect(onPressedOf(tester, FightStep.simulateKey), isNull);

      await pumpStep(tester, _draft(first: 'success'), fightIndex: 1);
      expect(onPressedOf(tester, FightStep.simulateKey), isNotNull);
    },
  );

  testWidgets('«Simula» on fight 1 calls simulate(0) (D-04)', (tester) async {
    await pumpStep(tester, _draft());

    expect(find.text(FightStep.simulateLabel), findsOneWidget);
    expect(find.text('3x Lupo'), findsOneWidget);
    await tester.tap(find.byKey(FightStep.simulateKey));

    expect(simulations, 1);
  });

  testWidgets(
    'a simulated fight shows «Rilancia» and calling it simulates again (D-05)',
    (tester) async {
      await pumpStep(tester, _draft(first: 'failure'));

      expect(find.text(FightStep.rerunLabel), findsOneWidget);
      expect(find.text(FightStep.simulateLabel), findsNothing);
      await tester.tap(find.byKey(FightStep.simulateKey));

      expect(simulations, 1);
    },
  );

  testWidgets(
    'a not simulated fight reads «Da simulare», hides the corrections and disables «Avanti» (D-24)',
    (tester) async {
      await pumpStep(tester, _draft(first: 'success'), fightIndex: 1);

      expect(find.text(EncountersStep.notSimulatedLabel), findsOneWidget);
      // UAT 2026-11-14: l'esito sta in alto e al centro, non fra i pulsanti
      final verdict = tester.getRect(find.byKey(FightStep.verdictKey));
      final simulate = tester.getRect(find.byKey(FightStep.simulateKey));
      final page = tester.getRect(find.byType(FightStep));
      expect(verdict.bottom, lessThan(simulate.top));
      expect(verdict.center.dx, moreOrLessEquals(page.center.dx, epsilon: 1));
      expect(find.byType(CorrectionSection), findsNothing);
      expect(onPressedOf(tester, MissionCompletionScreen.nextKey), isNull);
    },
  );

  testWidgets(
    'the verdict reads «Sconfitta» on the fight, not per character (D-21)',
    (tester) async {
      await pumpStep(tester, _draft(first: 'failure'));

      expect(find.text('Sconfitta'), findsOneWidget);
      expect(find.byType(CorrectionSection), findsWidgets);
    },
  );

  testWidgets('«Cambia nemici» goes back to the encounters (D-05)', (
    tester,
  ) async {
    await pumpStep(tester, _draft(first: 'success'));

    await tester.tap(find.byKey(FightStep.changeEnemiesKey));

    expect(enemyChanges, 1);
    expect(find.text(FightStep.changeEnemiesLabel), findsOneWidget);
  });

  testWidgets('while a call is in flight nothing can be pressed', (
    tester,
  ) async {
    await pumpStep(tester, _draft(first: 'success'), isSubmitting: true);

    expect(onPressedOf(tester, FightStep.simulateKey), isNull);
    expect(onPressedOf(tester, FightStep.changeEnemiesKey), isNull);
    expect(onPressedOf(tester, MissionCompletionScreen.nextKey), isNull);
  });

  testWidgets('a new served simulation resets the local corrections (D-09)', (
    tester,
  ) async {
    await pumpStep(tester, _draft(first: 'success'));
    final aldo = sectionOf(tester, _aldo);
    aldo.onChanged(aldo.correction.withHp(500));
    await tester.pump();
    expect(sectionOf(tester, _aldo).correction.hpAfter, 500);

    await pumpStep(tester, _draft(first: 'failure', aldoHp: 600));

    expect(sectionOf(tester, _aldo).correction.hpAfter, 600);
  });

  testWidgets(
    '«Avanti» sends one correction per participant in participant order, each with hpAfter, even for participants not touched (D-06, BE handoff)',
    (tester) async {
      await pumpStep(tester, _draft(first: 'success'));
      final aldo = sectionOf(tester, _aldo);
      aldo.onChanged(aldo.correction.withHp(650));
      await tester.pump();

      await tester.ensureVisible(find.byKey(MissionCompletionScreen.nextKey));
      await tester.tap(find.byKey(MissionCompletionScreen.nextKey));

      expect(sent, hasLength(1));
      expect(
        [
          for (final correction in sent.single)
            (correction.characterId, correction.hpAfter),
        ],
        [(_aldo, 650), (_bea, 750)],
      );
    },
  );

  group('wound removal (Phase 24)', () {
    Future<void> openSectionOf(WidgetTester tester, String characterId) async {
      await tester.tap(find.byKey(CorrectionSection.headerKeyFor(characterId)));
      await tester.pumpAndSettle();
    }

    FilterChip keptChip(WidgetTester tester, InjuryType injury) =>
        tester.widget<FilterChip>(find.byKey(InjuryChips.keptKeyOf(injury)));

    testWidgets(
      '«Avanti» sends the complete corrections with the wounds removed (D-13)',
      (tester) async {
        final draft = _draft(first: 'success');
        await pumpStep(tester, draft, isWoundRemovalEnabled: true);
        await openSectionOf(tester, _aldo);

        keptChip(tester, InjuryType.blackEye).onSelected!(false);
        await tester.pump();
        await tester.ensureVisible(find.byKey(MissionCompletionScreen.nextKey));
        await tester.tap(find.byKey(MissionCompletionScreen.nextKey));

        final [aldo, bea] = sent.single;
        expect(aldo.injuriesRemoved, [InjuryType.blackEye]);
        expect(aldo.hpAfter, 700);
        expect(
          bea,
          MissionCorrection.fromEffects(
            _bea,
            draft.fights.first.outcomeOf(_bea)!.effective!,
          ),
        );
        expect(bea.injuriesRemoved, isEmpty);
      },
    );

    testWidgets('a served correction with removals reopens with them (D-13)', (
      tester,
    ) async {
      await pumpStep(
        tester,
        _draft(
          first: 'success',
          aldoCorrected: missionEffectsJson(
            injuriesRemoved: const ['blackEye'],
          ),
        ),
        isWoundRemovalEnabled: true,
      );
      await openSectionOf(tester, _aldo);

      expect(keptChip(tester, InjuryType.blackEye).selected, isFalse);
    });

    testWidgets(
      'with the switch off the fight step offers no removal (pre-gate)',
      (tester) async {
        await pumpStep(tester, _draft(first: 'success'));
        await openSectionOf(tester, _aldo);

        final carried = keptChip(tester, InjuryType.blackEye);
        expect((carried.selected, carried.onSelected), (true, null));
        expect(find.byKey(InjuryChips.innkeeperNoteKey), findsNothing);
        expect(
          tester
              .widgetList<CorrectionSection>(find.byType(CorrectionSection))
              .every((section) => !section.isWoundRemovalEnabled),
          isTrue,
        );
      },
    );
  });

  testWidgets(
    'correcting the hero resends the simulated companion life (D-33, BE A-08)',
    (tester) async {
      final draft = MissionDraft.tryFromJson(
        missionDraftJson(
          step: 'fights',
          participants: [missionParticipantJson()],
          fights: [
            missionFightJson(
              verdict: 'success',
              outcomes: [
                missionOutcomeJson(
                  companion: missionCompanionJson(),
                  simulated: missionEffectsJson(companionLifeAfter: 120),
                ),
              ],
            ),
          ],
        ),
      )!;
      await pumpStep(tester, draft);
      final aldo = sectionOf(tester, _aldo);
      aldo.onChanged(aldo.correction.withHp(650));
      await tester.pump();

      await tester.ensureVisible(find.byKey(MissionCompletionScreen.nextKey));
      await tester.tap(find.byKey(MissionCompletionScreen.nextKey));

      final sentAldo = sent.single.single;
      expect(sentAldo.hpAfter, 650);
      expect(sentAldo.toJson()['companionLifeAfter'], 120);
    },
  );
}
