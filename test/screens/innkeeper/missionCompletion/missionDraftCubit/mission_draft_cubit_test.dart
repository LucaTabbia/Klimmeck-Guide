import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/coins.dart';
import 'package:klimmeck_guide/models/mission/mission_draft.dart';
import 'package:klimmeck_guide/models/quest_result/quest_result.dart';
import 'package:klimmeck_guide/models/request/mission_draft_inputs.dart';
import 'package:klimmeck_guide/repository/innkeeper_failure.dart';
import 'package:klimmeck_guide/screens/innkeeper/missionCompletion/missionDraftCubit/mission_draft_cubit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/fixtures/mission_fixtures.dart';
import '../../../../helpers/fixtures/quest_result_fixtures.dart';
import '../../../../helpers/mocks.dart';

const String _pendingQuestId = 'pq-world-1';
const String _aldo = 'char-aldo';
const String _bea = 'char-bea';

MissionDraft _draftOf(Map<String, dynamic> json) =>
    MissionDraft.tryFromJson(json)!;

final MissionDraft _served = _draftOf(missionDraftJson());

final MissionDraft _withFights = _draftOf(
  missionDraftJson(
    step: 'fights',
    place: 'poi-ruins-1',
    participants: [
      missionParticipantJson(),
      missionParticipantJson(character: _bea, name: 'Bea'),
    ],
    fights: [
      missionFightJson(
        verdict: 'success',
        outcomes: [
          missionOutcomeJson(
            simulated: missionEffectsJson(),
            corrected: missionEffectsJson(hpAfter: 750, injuriesAdded: []),
          ),
          missionOutcomeJson(
            character: _bea,
            simulated: missionEffectsJson(hpAfter: 600),
          ),
        ],
      ),
      missionFightJson(
        enemies: [
          missionFightEnemyJson(
            enemy: missionEnemyJson(id: 'enemy-goblin', name: 'Goblin'),
            quantity: 2,
          ),
        ],
        verdict: 'failure',
        outcomes: [
          missionOutcomeJson(simulated: missionEffectsJson(hpAfter: 300)),
          missionOutcomeJson(
            character: _bea,
            simulated: missionEffectsJson(hpAfter: 200),
          ),
        ],
      ),
    ],
  ),
);

final MissionDraft _afterSave = _draftOf(
  missionDraftJson(step: 'fights', place: 'poi-ruins-1'),
);

final List<QuestResult> _results = [
  QuestResult.fromJson(questResultJson(id: 'result-aldo', character: _aldo)),
];

void main() {
  late MockInnkeeperRepository repository;

  setUpAll(() {
    registerFallbackValue(
      const SaveMissionDraftInput(pendingQuestId: _pendingQuestId),
    );
    registerFallbackValue(
      const SimulateMissionFightInput(
        pendingQuestId: _pendingQuestId,
        fightIndex: 0,
        enemies: [],
      ),
    );
  });

  setUp(() {
    repository = MockInnkeeperRepository();
    when(
      () => repository.saveMissionDraft(any()),
    ).thenAnswer((_) async => _afterSave);
    when(
      () => repository.simulateMissionFight(any()),
    ).thenAnswer((_) async => _withFights);
  });

  MissionDraftCubit build() => MissionDraftCubit(
    repository: repository,
    pendingQuestId: _pendingQuestId,
  );

  SaveMissionDraftInput savedInput() =>
      verify(() => repository.saveMissionDraft(captureAny())).captured.single
          as SaveMissionDraftInput;

  test('starts loading', () {
    expect(build().state, const MissionDraftLoading());
  });

  group('load', () {
    blocTest<MissionDraftCubit, MissionDraftState>(
      'load without a draft is absent: no draft is created on open (D-28)',
      setUp: () => when(
        () => repository.readMissionDraft(_pendingQuestId),
      ).thenAnswer((_) async => null),
      build: build,
      act: (cubit) => cubit.load(),
      expect: () => [const MissionDraftAbsent()],
      verify: (_) {
        verify(() => repository.readMissionDraft(_pendingQuestId)).called(1);
        verifyNever(() => repository.startMissionDraft(any()));
      },
    );

    blocTest<MissionDraftCubit, MissionDraftState>(
      'load with a served draft is ready at the served draft (D-09)',
      setUp: () => when(
        () => repository.readMissionDraft(_pendingQuestId),
      ).thenAnswer((_) async => _withFights),
      build: build,
      act: (cubit) => cubit.load(),
      expect: () => [MissionDraftReady(draft: _withFights)],
    );

    blocTest<MissionDraftCubit, MissionDraftState>(
      'load failure is loadFailed; load again retries',
      setUp: () => when(
        () => repository.readMissionDraft(_pendingQuestId),
      ).thenThrow(const InnkeeperException(InnkeeperFailure.connection)),
      build: build,
      act: (cubit) async {
        await cubit.load();
        when(
          () => repository.readMissionDraft(_pendingQuestId),
        ).thenAnswer((_) async => _served);
        await cubit.load();
      },
      expect: () => [
        const MissionDraftLoadFailed(failure: InnkeeperFailure.connection),
        const MissionDraftLoading(),
        MissionDraftReady(draft: _served),
      ],
    );

    blocTest<MissionDraftCubit, MissionDraftState>(
      'load is ignored once the draft is ready',
      build: build,
      seed: () => MissionDraftReady(draft: _served),
      act: (cubit) => cubit.load(),
      expect: () => <MissionDraftState>[],
      verify: (_) => verifyNever(() => repository.readMissionDraft(any())),
    );
  });

  group('start', () {
    blocTest<MissionDraftCubit, MissionDraftState>(
      'start creates the draft explicitly (D-11, D-28)',
      setUp: () => when(
        () => repository.startMissionDraft(_pendingQuestId),
      ).thenAnswer((_) async => _served),
      build: build,
      seed: () => const MissionDraftAbsent(),
      act: (cubit) => cubit.start(),
      expect: () => [
        const MissionDraftAbsent(isStarting: true),
        MissionDraftReady(draft: _served),
      ],
      verify: (_) =>
          verify(() => repository.startMissionDraft(_pendingQuestId)).called(1),
    );

    blocTest<MissionDraftCubit, MissionDraftState>(
      'start refused keeps the start page with the failure (D-25)',
      setUp: () => when(
        () => repository.startMissionDraft(_pendingQuestId),
      ).thenThrow(const InnkeeperException(InnkeeperFailure.notFound)),
      build: build,
      seed: () => const MissionDraftAbsent(),
      act: (cubit) => cubit.start(),
      expect: () => [
        const MissionDraftAbsent(isStarting: true),
        const MissionDraftAbsent(
          failure: InnkeeperFailure.notFound,
          failureSerial: 1,
        ),
      ],
    );

    blocTest<MissionDraftCubit, MissionDraftState>(
      'a second start while starting is ignored',
      setUp: () => when(
        () => repository.startMissionDraft(_pendingQuestId),
      ).thenAnswer((_) async => _served),
      build: build,
      seed: () => const MissionDraftAbsent(),
      act: (cubit) => Future.wait([cubit.start(), cubit.start()]),
      verify: (_) =>
          verify(() => repository.startMissionDraft(_pendingQuestId)).called(1),
    );
  });

  group('saving the served draft', () {
    blocTest<MissionDraftCubit, MissionDraftState>(
      'saveStep sends only the step and the place (D-18)',
      build: build,
      seed: () => MissionDraftReady(draft: _served),
      act: (cubit) =>
          cubit.saveStep(MissionDraftStep.fights, placeId: 'poi-ruins-1'),
      expect: () => [
        MissionDraftReady(draft: _served, isSubmitting: true),
        MissionDraftReady(draft: _afterSave),
      ],
      verify: (_) => expect(savedInput().toJson(), {
        'pendingQuestId': _pendingQuestId,
        'step': 'fights',
        'place': 'poi-ruins-1',
      }),
    );

    final picks = [
      const [MissionEnemyInput(enemyId: 'enemy-wolf', quantity: 3)],
      const [
        MissionEnemyInput(enemyId: 'enemy-goblin', quantity: 4),
        MissionEnemyInput(enemyId: 'enemy-wolf', quantity: 1),
      ],
    ];

    blocTest<MissionDraftCubit, MissionDraftState>(
      'saveFights rebuilds the fights from the served draft (D-02, D-24)',
      build: build,
      seed: () => MissionDraftReady(draft: _withFights),
      act: (cubit) => cubit.saveFights(picks, step: MissionDraftStep.fights),
      expect: () => [
        MissionDraftReady(draft: _withFights, isSubmitting: true),
        MissionDraftReady(draft: _afterSave),
      ],
      verify: (_) => expect(savedInput().toJson(), {
        'pendingQuestId': _pendingQuestId,
        'step': 'fights',
        'fights': [
          for (final fight in fightsInputWithEnemies(_withFights, picks))
            fight.toJson(),
        ],
      }),
    );

    blocTest<MissionDraftCubit, MissionDraftState>(
      'zero fights moves on to the prizes (D-24)',
      build: build,
      seed: () => MissionDraftReady(draft: _withFights),
      act: (cubit) => cubit.saveFights(const [], step: MissionDraftStep.prizes),
      verify: (_) => expect(savedInput().toJson(), {
        'pendingQuestId': _pendingQuestId,
        'step': 'prizes',
        'fights': <Object>[],
      }),
    );

    blocTest<MissionDraftCubit, MissionDraftState>(
      'simulate sends the served enemies of the fight (D-04, D-24)',
      build: build,
      seed: () => MissionDraftReady(draft: _withFights),
      act: (cubit) => cubit.simulate(1),
      expect: () => [
        MissionDraftReady(draft: _withFights, isSubmitting: true),
        MissionDraftReady(draft: _withFights),
      ],
      verify: (_) => verify(
        () => repository.simulateMissionFight(
          const SimulateMissionFightInput(
            pendingQuestId: _pendingQuestId,
            fightIndex: 1,
            enemies: [MissionEnemyInput(enemyId: 'enemy-goblin', quantity: 2)],
          ),
        ),
      ).called(1),
    );

    blocTest<MissionDraftCubit, MissionDraftState>(
      'simulate of a fight the served draft does not have sends nothing',
      build: build,
      seed: () => MissionDraftReady(draft: _withFights),
      act: (cubit) => cubit.simulate(2),
      expect: () => <MissionDraftState>[],
      verify: (_) => verifyNever(() => repository.simulateMissionFight(any())),
    );

    blocTest<MissionDraftCubit, MissionDraftState>(
      'rerun is the same call again (D-05)',
      build: build,
      seed: () => MissionDraftReady(draft: _withFights),
      act: (cubit) async {
        await cubit.simulate(0);
        await cubit.simulate(0);
      },
      verify: (_) => verify(
        () => repository.simulateMissionFight(
          const SimulateMissionFightInput(
            pendingQuestId: _pendingQuestId,
            fightIndex: 0,
            enemies: [MissionEnemyInput(enemyId: 'enemy-wolf', quantity: 3)],
          ),
        ),
      ).called(2),
    );

    const correction = MissionCorrection(characterId: _bea, hpAfter: 450);

    blocTest<MissionDraftCubit, MissionDraftState>(
      "saveCorrections replaces only that fight's corrections (D-06, D-14)",
      build: build,
      seed: () => MissionDraftReady(draft: _withFights),
      act: (cubit) => cubit.saveCorrections(1, const [correction]),
      verify: (_) {
        final fights = savedInput().toJson()['fights'] as List<Object?>;
        expect(fights, [
          for (final fight in fightsInputWithCorrections(_withFights, 1, const [
            correction,
          ]))
            fight.toJson(),
        ]);
        expect(
          (fights[0] as Map<String, dynamic>)['corrections'],
          hasLength(2),
          reason: 'fight 0 keeps its served corrections',
        );
        expect((fights[1] as Map<String, dynamic>)['corrections'], [
          _aldoCorrectionInFightOne(),
          correction.toJson(),
        ]);
      },
    );

    final prizes = [
      const MissionPrizeInput(
        characterId: _aldo,
        coins: Coins(gold: 2, silver: 0, copper: 0),
        xp: 150,
        cure: true,
      ),
      const MissionPrizeInput(
        characterId: _bea,
        coins: Coins(gold: 0, silver: 5, copper: 0),
        xp: 0,
        cure: false,
        petId: 'pet-owl',
      ),
    ];

    blocTest<MissionDraftCubit, MissionDraftState>(
      'savePrizes sends every prize input (D-15, D-22)',
      build: build,
      seed: () => MissionDraftReady(draft: _withFights),
      act: (cubit) => cubit.savePrizes(prizes, step: MissionDraftStep.recap),
      verify: (_) => expect(savedInput().toJson(), {
        'pendingQuestId': _pendingQuestId,
        'step': 'recap',
        'prizes': [for (final prize in prizes) prize.toJson()],
      }),
    );

    final voided = _draftOf(
      missionDraftJson(
        step: 'fights',
        fights: [
          missionFightJson(outcomes: [missionOutcomeJson()]),
        ],
      ),
    );

    blocTest<MissionDraftCubit, MissionDraftState>(
      'the served draft replaces the state, nothing is merged locally (D-09)',
      setUp: () => when(
        () => repository.saveMissionDraft(any()),
      ).thenAnswer((_) async => voided),
      build: build,
      seed: () => MissionDraftReady(draft: _withFights),
      act: (cubit) => cubit.saveFights(picks),
      verify: (cubit) {
        final state = cubit.state as MissionDraftReady;
        expect(state.draft, same(voided));
        expect(state.draft.fights.single.verdict, isNull);
      },
    );
  });

  group('one call at a time', () {
    test('a second action while submitting is ignored', () async {
      final save = Completer<MissionDraft>();
      when(
        () => repository.saveMissionDraft(any()),
      ).thenAnswer((_) => save.future);
      when(
        () => repository.completeGuidedMission(_pendingQuestId),
      ).thenAnswer((_) async => _results);
      when(
        () => repository.readMissionDraft(_pendingQuestId),
      ).thenAnswer((_) async => _served);
      final cubit = build();
      await cubit.load();

      final first = cubit.saveStep(MissionDraftStep.fights);
      await cubit.saveStep(MissionDraftStep.prizes);
      await cubit.complete();
      save.complete(_afterSave);
      await first;

      verify(() => repository.saveMissionDraft(any())).called(1);
      verifyNever(() => repository.completeGuidedMission(any()));
      expect(cubit.state, MissionDraftReady(draft: _afterSave));
      await cubit.close();
    });

    blocTest<MissionDraftCubit, MissionDraftState>(
      'actions are ignored without a served draft',
      build: build,
      seed: () => const MissionDraftAbsent(),
      act: (cubit) async {
        await cubit.saveStep(MissionDraftStep.fights);
        await cubit.simulate(0);
        await cubit.discard();
        await cubit.complete();
      },
      expect: () => <MissionDraftState>[],
      verify: (_) {
        verifyNever(() => repository.saveMissionDraft(any()));
        verifyNever(() => repository.simulateMissionFight(any()));
        verifyNever(() => repository.discardMissionDraft(any()));
        verifyNever(() => repository.completeGuidedMission(any()));
      },
    );
  });

  group('refusals', () {
    blocTest<MissionDraftCubit, MissionDraftState>(
      'a refused save keeps the old draft with the failure and a new serial '
      '(D-14)',
      setUp: () => when(
        () => repository.saveMissionDraft(any()),
      ).thenThrow(const InnkeeperException(InnkeeperFailure.overrideInvalid)),
      build: build,
      seed: () => MissionDraftReady(draft: _withFights, failureSerial: 2),
      act: (cubit) => cubit.saveCorrections(0, const []),
      expect: () => [
        MissionDraftReady(
          draft: _withFights,
          isSubmitting: true,
          failureSerial: 2,
        ),
        MissionDraftReady(
          draft: _withFights,
          failure: InnkeeperFailure.overrideInvalid,
          failureSerial: 3,
        ),
      ],
    );

    blocTest<MissionDraftCubit, MissionDraftState>(
      'the next action clears the shown failure',
      build: build,
      seed: () => MissionDraftReady(
        draft: _served,
        failure: InnkeeperFailure.overrideInvalid,
        failureSerial: 1,
      ),
      act: (cubit) => cubit.saveStep(MissionDraftStep.fights),
      expect: () => [
        MissionDraftReady(draft: _served, isSubmitting: true, failureSerial: 1),
        MissionDraftReady(draft: _afterSave, failureSerial: 1),
      ],
    );

    blocTest<MissionDraftCubit, MissionDraftState>(
      'a refused completion keeps the draft for the exits (D-25)',
      setUp: () => when(
        () => repository.completeGuidedMission(_pendingQuestId),
      ).thenThrow(const InnkeeperException(InnkeeperFailure.questInProgress)),
      build: build,
      seed: () => MissionDraftReady(draft: _served),
      act: (cubit) => cubit.complete(),
      expect: () => [
        MissionDraftReady(draft: _served, isSubmitting: true),
        MissionDraftReady(
          draft: _served,
          failure: InnkeeperFailure.questInProgress,
          failureSerial: 1,
        ),
      ],
    );
  });

  group('ending', () {
    blocTest<MissionDraftCubit, MissionDraftState>(
      'discard ends discarded (D-11)',
      setUp: () => when(
        () => repository.discardMissionDraft(_pendingQuestId),
      ).thenAnswer((_) async {}),
      build: build,
      seed: () => MissionDraftReady(draft: _served),
      act: (cubit) => cubit.discard(),
      expect: () => [
        MissionDraftReady(draft: _served, isSubmitting: true),
        const MissionDraftDiscarded(),
      ],
      verify: (_) => verify(
        () => repository.discardMissionDraft(_pendingQuestId),
      ).called(1),
    );

    blocTest<MissionDraftCubit, MissionDraftState>(
      'complete ends completed with the results (D-08, D-25)',
      setUp: () => when(
        () => repository.completeGuidedMission(_pendingQuestId),
      ).thenAnswer((_) async => _results),
      build: build,
      seed: () => MissionDraftReady(draft: _served),
      act: (cubit) => cubit.complete(),
      expect: () => [
        MissionDraftReady(draft: _served, isSubmitting: true),
        MissionDraftCompleted(results: _results),
      ],
    );
  });
}

/// Aldo non è corretto a mano: la lista completa lo rimanda col suo effetto
/// servito (simulated, hpAfter 300).
Map<String, dynamic> _aldoCorrectionInFightOne() => {
  'characterId': _aldo,
  'hpAfter': 300,
  'injuries': ['crushedRightHand'],
  'consumablesUsed': <Object>[],
  'spellsUsed': <Object>[],
};
