import 'package:flutter_test/flutter_test.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:klimmeck_guide/models/mission/mission_draft.dart';
import 'package:klimmeck_guide/models/request/mission_draft_inputs.dart';
import 'package:klimmeck_guide/repository/services/graphql/graphql.dart';
import 'package:klimmeck_guide/repository/services/graphql/graphql_error_code.dart';

import '../../../helpers/fixtures/mission_fixtures.dart';
import '../../../helpers/fixtures/quest_result_fixtures.dart';
import '../../../helpers/fixtures/sync_event_fixtures.dart';
import 'graphql_sync_test.dart' show operationNameOf;

Matcher _operationCoded(String code) =>
    throwsA(isA<OperationException>().having(graphQlErrorCode, 'code', code));

void main() {
  const pendingQuestId = 'pq-world-1';
  const saveInput = SaveMissionDraftInput(
    pendingQuestId: pendingQuestId,
    step: MissionDraftStep.fights,
    placeId: 'poi-ruins-1',
  );
  const simulateInput = SimulateMissionFightInput(
    pendingQuestId: pendingQuestId,
    fightIndex: 0,
    enemies: [MissionEnemyInput(enemyId: 'enemy-wolf', quantity: 3)],
  );

  late List<Request> requests;
  late Stream<Response> Function(Request request) handler;

  KlimmeckGraphQl buildGraphQl() => KlimmeckGraphQl(
    resolveClient: () => GraphQLClient(
      link: Link.function((request, [forward]) {
        requests.add(request);
        return handler(request);
      }),
      cache: GraphQLCache(store: InMemoryStore()),
    ),
  );

  void respond(Map<String, dynamic> data) =>
      handler = (_) => Stream.value(dataResponse(data));

  setUp(() {
    requests = [];
    handler = (_) => const Stream.empty();
  });

  group('getMissionDraft', () {
    test('sends GetMissionDraft and parses the served draft (D-09)', () async {
      respond({'missionDraft': missionDraftJson()});

      final draft = await buildGraphQl().getMissionDraft(pendingQuestId);

      expect(operationNameOf(requests.single), 'GetMissionDraft');
      expect(requests.single.variables, {'pendingQuestId': pendingQuestId});
      expect(draft?.id, 'draft-1');
    });

    test('a null missionDraft is no draft (D-09)', () async {
      respond({'missionDraft': null});

      expect(await buildGraphQl().getMissionDraft(pendingQuestId), isNull);
    });

    test('a malformed draft is a FormatException (Pitfall 8)', () async {
      respond({
        'missionDraft': {'id': 'broken'},
      });

      await expectLater(
        buildGraphQl().getMissionDraft(pendingQuestId),
        throwsFormatException,
      );
    });
  });

  group('startMissionDraft', () {
    test('sends StartMissionDraft and parses the draft (D-28)', () async {
      respond({'startMissionDraft': missionDraftJson()});

      final draft = await buildGraphQl().startMissionDraft(pendingQuestId);

      expect(operationNameOf(requests.single), 'StartMissionDraft');
      expect(requests.single.variables, {'pendingQuestId': pendingQuestId});
      expect(draft.id, 'draft-1');
    });

    test('a missing draft is a FormatException (Pitfall 8)', () async {
      respond({'startMissionDraft': null});

      await expectLater(
        buildGraphQl().startMissionDraft(pendingQuestId),
        throwsFormatException,
      );
    });
  });

  group('saveMissionDraft', () {
    test('sends SaveMissionDraft with the input variable (D-18)', () async {
      respond({'saveMissionDraft': missionDraftJson(step: 'fights')});

      final draft = await buildGraphQl().saveMissionDraft(saveInput);

      expect(operationNameOf(requests.single), 'SaveMissionDraft');
      expect(requests.single.variables, {'input': saveInput.toJson()});
      expect(draft.step, MissionDraftStep.fights);
    });

    test('a malformed draft is a FormatException (Pitfall 8)', () async {
      respond({
        'saveMissionDraft': {'id': 'broken'},
      });

      await expectLater(
        buildGraphQl().saveMissionDraft(saveInput),
        throwsFormatException,
      );
    });
  });

  group('simulateMissionFight', () {
    test('sends SimulateMissionFight with the input variable (D-04)', () async {
      respond({'simulateMissionFight': missionDraftJson()});

      final draft = await buildGraphQl().simulateMissionFight(simulateInput);

      expect(operationNameOf(requests.single), 'SimulateMissionFight');
      expect(requests.single.variables, {'input': simulateInput.toJson()});
      expect(draft.id, 'draft-1');
    });
  });

  group('discardMissionDraft', () {
    test('discard returns successful (D-09)', () async {
      respond({
        'discardMissionDraft': {'successful': true, 'response': 'ok'},
      });

      final discarded = await buildGraphQl().discardMissionDraft(
        pendingQuestId,
      );

      expect(operationNameOf(requests.single), 'DiscardMissionDraft');
      expect(requests.single.variables, {'pendingQuestId': pendingQuestId});
      expect(discarded, isTrue);
    });

    test('discard returns successful false as false (D-09)', () async {
      respond({
        'discardMissionDraft': {'successful': false, 'response': 'no'},
      });

      expect(await buildGraphQl().discardMissionDraft(pendingQuestId), false);
    });

    test('a response without successful is a FormatException', () async {
      respond({'discardMissionDraft': null});

      await expectLater(
        buildGraphQl().discardMissionDraft(pendingQuestId),
        throwsFormatException,
      );
    });
  });

  group('completeGuidedMission', () {
    test('sends CompleteGuidedMission with the pending quest (D-08)', () async {
      respond({
        'completeGuidedMission': [gmCompletedResultJson()],
      });

      await buildGraphQl().completeGuidedMission(pendingQuestId);

      expect(operationNameOf(requests.single), 'CompleteGuidedMission');
      expect(requests.single.variables, {'pendingQuestId': pendingQuestId});
    });

    test('complete parses every result, a malformed one is dropped '
        '(D-08)', () async {
      respond({
        'completeGuidedMission': [
          gmCompletedResultJson(id: 'r-1'),
          {'id': 'broken'},
          gmCompletedResultJson(id: 'r-2'),
        ],
      });

      final results = await buildGraphQl().completeGuidedMission(
        pendingQuestId,
      );

      expect(results.map((result) => result.id), ['r-1', 'r-2']);
    });

    test('a payload that is not a list is a FormatException', () async {
      respond({'completeGuidedMission': null});

      await expectLater(
        buildGraphQl().completeGuidedMission(pendingQuestId),
        throwsFormatException,
      );
    });
  });

  group('getMissionEnemies', () {
    test('sends ListMissionEnemies with showAll (D-03)', () async {
      respond({
        'missionEnemies': [missionEnemyJson()],
      });

      final enemies = await buildGraphQl().getMissionEnemies(
        pendingQuestId,
        showAll: true,
      );

      expect(operationNameOf(requests.single), 'ListMissionEnemies');
      expect(requests.single.variables, {
        'pendingQuestId': pendingQuestId,
        'showAll': true,
      });
      expect(enemies.map((enemy) => enemy.id), ['enemy-wolf']);
    });

    test('showAll is false by default (D-03)', () async {
      respond({'missionEnemies': <Object>[]});

      await buildGraphQl().getMissionEnemies(pendingQuestId);

      expect(requests.single.variables, {
        'pendingQuestId': pendingQuestId,
        'showAll': false,
      });
    });

    test('a malformed enemy is dropped, the list stays in the served order '
        '(Pitfall 8, D-19)', () async {
      respond({
        'missionEnemies': [
          missionEnemyJson(id: 'enemy-wolf'),
          {'id': 'broken'},
          missionEnemyJson(id: 'enemy-bear', name: 'Orso'),
        ],
      });

      final enemies = await buildGraphQl().getMissionEnemies(pendingQuestId);

      expect(enemies.map((enemy) => enemy.id), ['enemy-wolf', 'enemy-bear']);
    });

    test('a missing list is a FormatException', () async {
      respond({'missionEnemies': null});

      await expectLater(
        buildGraphQl().getMissionEnemies(pendingQuestId),
        throwsFormatException,
      );
    });
  });

  group('getMissionPrizeOptions', () {
    test('sends GetMissionPrizeOptions with character and pending quest '
        '(D-07)', () async {
      respond({'missionPrizeOptions': missionPrizeOptionsJson()});

      final options = await buildGraphQl().getMissionPrizeOptions(
        pendingQuestId: pendingQuestId,
        characterId: 'char-aldo',
      );

      expect(operationNameOf(requests.single), 'GetMissionPrizeOptions');
      expect(requests.single.variables, {
        'characterId': 'char-aldo',
        'pendingQuestId': pendingQuestId,
      });
      expect(options.characterId, 'char-aldo');
    });

    test('malformed options are a FormatException (Pitfall 8)', () async {
      respond({'missionPrizeOptions': null});

      await expectLater(
        buildGraphQl().getMissionPrizeOptions(
          pendingQuestId: pendingQuestId,
          characterId: 'char-aldo',
        ),
        throwsFormatException,
      );
    });
  });

  test('an error keeps the OperationException code', () async {
    handler = (_) =>
        Stream.value(errorCodeResponse('OUTCOME_OVERRIDE_INVALID'));
    final graphQl = buildGraphQl();
    final calls = <Future<Object?> Function()>[
      () => graphQl.getMissionDraft(pendingQuestId),
      () => graphQl.startMissionDraft(pendingQuestId),
      () => graphQl.saveMissionDraft(saveInput),
      () => graphQl.simulateMissionFight(simulateInput),
      () => graphQl.discardMissionDraft(pendingQuestId),
      () => graphQl.completeGuidedMission(pendingQuestId),
      () => graphQl.getMissionEnemies(pendingQuestId),
      () => graphQl.getMissionPrizeOptions(
        pendingQuestId: pendingQuestId,
        characterId: 'char-aldo',
      ),
    ];

    for (final call in calls) {
      await expectLater(call(), _operationCoded('OUTCOME_OVERRIDE_INVALID'));
    }
  });
}
