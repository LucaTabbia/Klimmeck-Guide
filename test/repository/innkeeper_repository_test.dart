import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:klimmeck_guide/models/character/character.dart';
import 'package:klimmeck_guide/models/mission/mission_draft.dart';
import 'package:klimmeck_guide/models/mission/mission_enemy.dart';
import 'package:klimmeck_guide/models/mission/mission_prize_options.dart';
import 'package:klimmeck_guide/models/pending_request/pending_request.dart';
import 'package:klimmeck_guide/models/point_of_interest.dart';
import 'package:klimmeck_guide/models/quest_result/quest_result.dart';
import 'package:klimmeck_guide/models/request/mission_draft_inputs.dart';
import 'package:klimmeck_guide/models/request/travel_request.dart';
import 'package:klimmeck_guide/repository/innkeeper_failure.dart';
import 'package:klimmeck_guide/repository/innkeeper_repository.dart';
import 'package:klimmeck_guide/repository/services/graphql/graphql_sync_exceptions.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/fixtures/mission_fixtures.dart';
import '../helpers/fixtures/pending_request_fixtures.dart';
import '../helpers/fixtures/quest_result_fixtures.dart';
import '../helpers/fixtures/travel_fixtures.dart';
import '../helpers/mocks.dart';

Matcher _failsWith(InnkeeperFailure failure) => throwsA(
  isA<InnkeeperException>().having((e) => e.failure, 'failure', failure),
);

OperationException _coded(String code) => OperationException(
  graphqlErrors: [
    GraphQLError(message: 'server text', extensions: {'code': code}),
  ],
);

void main() {
  late MockKlimmeckGraphQl graphQl;
  late InnkeeperRepository repository;

  const teleportRequest = TravelRequest(
    id: 'char-bea',
    poiId: 'poi-borgo-marker',
  );

  const saveInput = SaveMissionDraftInput(pendingQuestId: 'pq-world-1');
  const simulateInput = SimulateMissionFightInput(
    pendingQuestId: 'pq-world-1',
    fightIndex: 0,
    enemies: [MissionEnemyInput(enemyId: 'enemy-wolf', quantity: 3)],
  );

  setUpAll(() {
    registerFallbackValue(teleportRequest);
    registerFallbackValue(saveInput);
    registerFallbackValue(simulateInput);
  });

  setUp(() {
    graphQl = MockKlimmeckGraphQl();
    repository = InnkeeperRepository(graphQl: graphQl);
  });

  test('times out after 15 seconds by default', () {
    expect(InnkeeperRepository.defaultTimeout, const Duration(seconds: 15));
  });

  test('watchQueue exposes the service stream unchanged', () {
    final stream = Stream<List<PendingRequest>>.value(const []);
    when(() => graphQl.subscribeToPendingRequests()).thenAnswer((_) => stream);

    expect(repository.watchQueue(), same(stream));
  });

  group('fetchQueue', () {
    test('passes the queue through', () async {
      final queue = [PendingRequest.fromJson(pendingRequestJson())];
      when(() => graphQl.getPendingRequests()).thenAnswer((_) async => queue);

      expect(await repository.fetchQueue(), queue);
    });

    test('maps FORBIDDEN to forbidden', () async {
      when(() => graphQl.getPendingRequests()).thenThrow(_coded('FORBIDDEN'));

      await expectLater(
        repository.fetchQueue(),
        _failsWith(InnkeeperFailure.forbidden),
      );
    });

    test('maps a FormatException to malformed', () async {
      when(
        () => graphQl.getPendingRequests(),
      ).thenThrow(const FormatException('pendingRequests missing'));

      await expectLater(
        repository.fetchQueue(),
        _failsWith(InnkeeperFailure.malformed),
      );
    });

    test('fails as timedOut after 15 seconds without an answer', () {
      fakeAsync((async) {
        when(
          () => graphQl.getPendingRequests(),
        ).thenAnswer((_) => Completer<List<PendingRequest>>().future);
        Object? failure;

        repository.fetchQueue().then<void>(
          (_) {},
          onError: (Object error) => failure = error,
        );
        async.elapse(const Duration(seconds: 14));
        expect(failure, isNull);
        async.elapse(const Duration(seconds: 1));

        expect(
          failure,
          isA<InnkeeperException>().having(
            (e) => e.failure,
            'failure',
            InnkeeperFailure.timedOut,
          ),
        );
      });
    });
  });

  group('readCharacter', () {
    test('passes the character through', () async {
      final character = Character.fromJson(
        participantCharacterJson(id: 'char-bea', name: 'Bea'),
      );
      when(
        () => graphQl.getCharacter('char-bea'),
      ).thenAnswer((_) async => character);

      expect(await repository.readCharacter('char-bea'), character);
    });

    final byCode = {
      'NOT_FOUND': InnkeeperFailure.notFound,
      'FORBIDDEN': InnkeeperFailure.forbidden,
    };
    byCode.forEach((code, failure) {
      test('maps an access denied $code to ${failure.name}', () async {
        when(() => graphQl.getCharacter(any())).thenThrow(
          GraphQlAccessDeniedException(operation: 'character', code: code),
        );

        await expectLater(
          repository.readCharacter('char-bea'),
          _failsWith(failure),
        );
      });
    });

    test('maps a plain Exception to unknown', () async {
      when(
        () => graphQl.getCharacter(any()),
      ).thenThrow(Exception('character read failed'));

      await expectLater(
        repository.readCharacter('char-bea'),
        _failsWith(InnkeeperFailure.unknown),
      );
    });
  });

  group('teleport', () {
    test('sends the character and the destination', () async {
      when(
        () => graphQl.teleportCharacter(any()),
      ).thenAnswer((_) async => true);

      await repository.teleport(
        characterId: 'char-bea',
        poiId: 'poi-borgo-marker',
      );

      verify(() => graphQl.teleportCharacter(teleportRequest)).called(1);
    });

    test('turns successful false into declined', () async {
      when(
        () => graphQl.teleportCharacter(any()),
      ).thenAnswer((_) async => false);

      await expectLater(
        repository.teleport(characterId: 'char-bea', poiId: 'poi-borgo-marker'),
        _failsWith(InnkeeperFailure.declined),
      );
    });

    test('maps QUEST_IN_PROGRESS to questInProgress', () async {
      when(
        () => graphQl.teleportCharacter(any()),
      ).thenThrow(_coded('QUEST_IN_PROGRESS'));

      await expectLater(
        repository.teleport(characterId: 'char-bea', poiId: 'poi-borgo-marker'),
        _failsWith(InnkeeperFailure.questInProgress),
      );
    });
  });

  group('generateQuests', () {
    test('passes the created count through (D-10)', () async {
      when(() => graphQl.generateQuests()).thenAnswer((_) async => 4);

      expect(await repository.generateQuests(), 4);
    });

    test('maps FORBIDDEN to forbidden (D-09)', () async {
      when(() => graphQl.generateQuests()).thenThrow(_coded('FORBIDDEN'));

      await expectLater(
        repository.generateQuests(),
        _failsWith(InnkeeperFailure.forbidden),
      );
    });

    test('maps UNAUTHENTICATED to unauthenticated (D-10)', () async {
      when(() => graphQl.generateQuests()).thenThrow(_coded('UNAUTHENTICATED'));

      await expectLater(
        repository.generateQuests(),
        _failsWith(InnkeeperFailure.unauthenticated),
      );
    });

    test('maps a link error without code to connection (D-09)', () async {
      when(() => graphQl.generateQuests()).thenThrow(
        OperationException(
          linkException: ServerException(
            originalException: Exception('offline'),
          ),
        ),
      );

      await expectLater(
        repository.generateQuests(),
        _failsWith(InnkeeperFailure.connection),
      );
    });

    test('maps a FormatException to malformed (D-10)', () async {
      when(
        () => graphQl.generateQuests(),
      ).thenThrow(const FormatException('generateQuests.created missing'));

      await expectLater(
        repository.generateQuests(),
        _failsWith(InnkeeperFailure.malformed),
      );
    });

    test('fails as timedOut after 15 seconds without an answer (D-10)', () {
      fakeAsync((async) {
        when(
          () => graphQl.generateQuests(),
        ).thenAnswer((_) => Completer<int>().future);
        Object? failure;

        repository.generateQuests().then<void>(
          (_) {},
          onError: (Object error) => failure = error,
        );
        async.elapse(const Duration(seconds: 14));
        expect(failure, isNull);
        async.elapse(const Duration(seconds: 1));

        expect(
          failure,
          isA<InnkeeperException>().having(
            (e) => e.failure,
            'failure',
            InnkeeperFailure.timedOut,
          ),
        );
      });
    });
  });

  group('listPointsOfInterest', () {
    test('listPointsOfInterest returns the service list (D-29)', () async {
      final places = [PointOfInterest.fromJson(pointOfInterestJson())];
      when(() => graphQl.getPointsOfInterest()).thenAnswer((_) async => places);

      expect(await repository.listPointsOfInterest(), places);
    });

    test('a FormatException is malformed (D-29)', () async {
      when(
        () => graphQl.getPointsOfInterest(),
      ).thenThrow(const FormatException('pointOfInterests missing'));

      await expectLater(
        repository.listPointsOfInterest(),
        _failsWith(InnkeeperFailure.malformed),
      );
    });

    test('FORBIDDEN is forbidden (D-29)', () async {
      when(() => graphQl.getPointsOfInterest()).thenThrow(_coded('FORBIDDEN'));

      await expectLater(
        repository.listPointsOfInterest(),
        _failsWith(InnkeeperFailure.forbidden),
      );
    });
  });

  group('guided mission (Phase 21)', () {
    const pendingQuestId = 'pq-world-1';
    final draft = MissionDraft.tryFromJson(missionDraftJson())!;

    test('readMissionDraft returns the served draft (D-09)', () async {
      when(
        () => graphQl.getMissionDraft(pendingQuestId),
      ).thenAnswer((_) async => draft);

      expect(await repository.readMissionDraft(pendingQuestId), draft);
    });

    test('readMissionDraft returns null when the BE has no draft '
        '(D-09)', () async {
      when(
        () => graphQl.getMissionDraft(pendingQuestId),
      ).thenAnswer((_) async => null);

      expect(await repository.readMissionDraft(pendingQuestId), isNull);
    });

    test('a malformed draft is malformed (Pitfall 8)', () async {
      when(
        () => graphQl.getMissionDraft(pendingQuestId),
      ).thenThrow(const FormatException('missionDraft malformed'));

      await expectLater(
        repository.readMissionDraft(pendingQuestId),
        _failsWith(InnkeeperFailure.malformed),
      );
    });

    test('startMissionDraft returns the created draft (D-28)', () async {
      when(
        () => graphQl.startMissionDraft(pendingQuestId),
      ).thenAnswer((_) async => draft);

      expect(await repository.startMissionDraft(pendingQuestId), draft);
    });

    test('NOT_FOUND on start is notFound (D-25)', () async {
      when(
        () => graphQl.startMissionDraft(pendingQuestId),
      ).thenThrow(_coded('NOT_FOUND'));

      await expectLater(
        repository.startMissionDraft(pendingQuestId),
        _failsWith(InnkeeperFailure.notFound),
      );
    });

    test('QUEST_IN_PROGRESS on start is questInProgress', () async {
      when(
        () => graphQl.startMissionDraft(pendingQuestId),
      ).thenThrow(_coded('QUEST_IN_PROGRESS'));

      await expectLater(
        repository.startMissionDraft(pendingQuestId),
        _failsWith(InnkeeperFailure.questInProgress),
      );
    });

    test('saveMissionDraft sends the input and returns the draft '
        '(D-18)', () async {
      when(
        () => graphQl.saveMissionDraft(saveInput),
      ).thenAnswer((_) async => draft);

      expect(await repository.saveMissionDraft(saveInput), draft);
      verify(() => graphQl.saveMissionDraft(saveInput)).called(1);
    });

    test('OUTCOME_OVERRIDE_INVALID on save is overrideInvalid '
        '(D-14, D-15)', () async {
      when(
        () => graphQl.saveMissionDraft(any()),
      ).thenThrow(_coded('OUTCOME_OVERRIDE_INVALID'));

      await expectLater(
        repository.saveMissionDraft(saveInput),
        _failsWith(InnkeeperFailure.overrideInvalid),
      );
    });

    test('simulateMissionFight returns the simulated draft (D-04)', () async {
      when(
        () => graphQl.simulateMissionFight(simulateInput),
      ).thenAnswer((_) async => draft);

      expect(await repository.simulateMissionFight(simulateInput), draft);
    });

    test('a timeout on simulate is timedOut', () {
      fakeAsync((async) {
        when(
          () => graphQl.simulateMissionFight(any()),
        ).thenAnswer((_) => Completer<MissionDraft>().future);
        Object? failure;

        repository
            .simulateMissionFight(simulateInput)
            .then<void>((_) {}, onError: (Object error) => failure = error);
        async.elapse(InnkeeperRepository.defaultTimeout);

        expect(
          failure,
          isA<InnkeeperException>().having(
            (e) => e.failure,
            'failure',
            InnkeeperFailure.timedOut,
          ),
        );
      });
    });

    test('discard true completes (D-09)', () async {
      when(
        () => graphQl.discardMissionDraft(pendingQuestId),
      ).thenAnswer((_) async => true);

      await repository.discardMissionDraft(pendingQuestId);

      verify(() => graphQl.discardMissionDraft(pendingQuestId)).called(1);
    });

    test('discard false is declined', () async {
      when(
        () => graphQl.discardMissionDraft(pendingQuestId),
      ).thenAnswer((_) async => false);

      await expectLater(
        repository.discardMissionDraft(pendingQuestId),
        _failsWith(InnkeeperFailure.declined),
      );
    });

    test('completeGuidedMission returns the created results (D-08)', () async {
      final results = [QuestResult.tryFromJson(gmCompletedResultJson())!];
      when(
        () => graphQl.completeGuidedMission(pendingQuestId),
      ).thenAnswer((_) async => results);

      expect(await repository.completeGuidedMission(pendingQuestId), results);
    });

    test('listMissionEnemies forwards showAll (D-03)', () async {
      final enemies = [MissionEnemy.tryFromJson(missionEnemyJson())!];
      when(
        () => graphQl.getMissionEnemies(pendingQuestId, showAll: true),
      ).thenAnswer((_) async => enemies);

      expect(
        await repository.listMissionEnemies(pendingQuestId, showAll: true),
        enemies,
      );
      verify(
        () => graphQl.getMissionEnemies(pendingQuestId, showAll: true),
      ).called(1);
    });

    test('listMissionEnemies asks the default list (D-03)', () async {
      when(
        () => graphQl.getMissionEnemies(pendingQuestId, showAll: false),
      ).thenAnswer((_) async => const []);

      expect(await repository.listMissionEnemies(pendingQuestId), isEmpty);
    });

    test('readMissionPrizeOptions passes the options through (D-07)', () async {
      final options = MissionPrizeOptions.tryFromJson(
        missionPrizeOptionsJson(),
      )!;
      when(
        () => graphQl.getMissionPrizeOptions(
          pendingQuestId: pendingQuestId,
          characterId: 'char-aldo',
        ),
      ).thenAnswer((_) async => options);

      expect(
        await repository.readMissionPrizeOptions(
          pendingQuestId: pendingQuestId,
          characterId: 'char-aldo',
        ),
        options,
      );
    });

    test('FORBIDDEN on complete is forbidden (T-21-35)', () async {
      when(
        () => graphQl.completeGuidedMission(pendingQuestId),
      ).thenThrow(_coded('FORBIDDEN'));

      await expectLater(
        repository.completeGuidedMission(pendingQuestId),
        _failsWith(InnkeeperFailure.forbidden),
      );
    });
  });
}
