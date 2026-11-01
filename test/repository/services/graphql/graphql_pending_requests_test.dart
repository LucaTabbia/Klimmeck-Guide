import 'package:flutter_test/flutter_test.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:klimmeck_guide/models/pending_request/pending_request.dart';
import 'package:klimmeck_guide/models/request/complete_pending_request_input.dart';
import 'package:klimmeck_guide/models/request/participant_override.dart';
import 'package:klimmeck_guide/repository/services/graphql/graphql.dart';
import 'package:klimmeck_guide/repository/services/graphql/graphql_error_code.dart';
import 'package:klimmeck_guide/repository/services/graphql/graphql_sync_exceptions.dart';

import '../../../helpers/fixtures/pending_request_fixtures.dart';
import '../../../helpers/fixtures/quest_result_fixtures.dart';
import '../../../helpers/fixtures/sync_event_fixtures.dart';
import 'graphql_sync_test.dart' show operationNameOf;

Matcher _streamFailure(String code) => isA<SubscriptionStreamException>()
    .having((e) => e.operation, 'operation', 'pendingRequestsUpdated')
    .having((e) => e.code, 'code', code);

Matcher _operationCoded(String code) =>
    throwsA(isA<OperationException>().having(graphQlErrorCode, 'code', code));

List<String> _idsOf(List<PendingRequest> queue) =>
    queue.map((request) => request.id).toList();

void main() {
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

  setUp(() {
    requests = [];
    handler = (_) => const Stream.empty();
  });

  group('subscribeToPendingRequests', () {
    test('sends OnPendingRequestsUpdated and emits each snapshot', () async {
      handler = (_) => Stream.fromIterable([
        dataResponse({
          'pendingRequestsUpdated': [pendingRequestJson()],
        }),
        dataResponse({
          'pendingRequestsUpdated': [
            pendingRequestJson(),
            ...worldMissionEntriesJson(),
          ],
        }),
      ]);

      final snapshots = await buildGraphQl()
          .subscribeToPendingRequests()
          .map(_idsOf)
          .toList();

      expect(operationNameOf(requests.single), 'OnPendingRequestsUpdated');
      expect(requests.single.variables, isEmpty);
      expect(snapshots, [
        ['pq-story-1'],
        ['pq-story-1', 'pq-world-1', 'pq-world-2'],
      ]);
    });

    test('skips a malformed entry and keeps the valid one', () async {
      handler = (_) => Stream.value(
        dataResponse({
          'pendingRequestsUpdated': [
            {'id': 'broken'},
            pendingRequestJson(),
          ],
        }),
      );

      final queue = await buildGraphQl().subscribeToPendingRequests().single;

      expect(_idsOf(queue), ['pq-story-1']);
    });

    test('keeps delivering after an event without the list', () {
      handler = (_) => Stream.fromIterable([
        dataResponse({'pendingRequestsUpdated': null}),
        dataResponse({
          'pendingRequestsUpdated': [pendingRequestJson()],
        }),
      ]);

      expect(
        buildGraphQl().subscribeToPendingRequests().map(_idsOf),
        emitsInOrder([
          emitsError(isA<FormatException>()),
          ['pq-story-1'],
          emitsDone,
        ]),
      );
    });

    test('maps FORBIDDEN to a typed stream error', () {
      handler = (_) => Stream.value(errorCodeResponse('FORBIDDEN'));

      expect(
        buildGraphQl().subscribeToPendingRequests(),
        emitsInOrder([emitsError(_streamFailure('FORBIDDEN')), emitsDone]),
      );
    });
  });

  group('getPendingRequests', () {
    test('sends GetPendingRequests and returns the parsed queue', () async {
      handler = (_) => Stream.value(
        dataResponse({
          'pendingRequests': [
            pendingRequestJson(),
            ...worldMissionEntriesJson(),
          ],
        }),
      );

      final queue = await buildGraphQl().getPendingRequests();

      expect(operationNameOf(requests.single), 'GetPendingRequests');
      expect(requests.single.variables, isEmpty);
      expect(_idsOf(queue), ['pq-story-1', 'pq-world-1', 'pq-world-2']);
    });

    test('skips a malformed entry and keeps the valid ones', () async {
      handler = (_) => Stream.value(
        dataResponse({
          'pendingRequests': [
            pendingRequestJson(),
            {'id': 'broken'},
          ],
        }),
      );

      expect(_idsOf(await buildGraphQl().getPendingRequests()), ['pq-story-1']);
    });

    test('turns a missing list into a FormatException', () async {
      handler = (_) => Stream.value(dataResponse({'pendingRequests': null}));

      await expectLater(
        buildGraphQl().getPendingRequests(),
        throwsFormatException,
      );
    });

    test('throws the raw OperationException keeping the code', () async {
      handler = (_) => Stream.value(errorCodeResponse('FORBIDDEN'));

      await expectLater(
        buildGraphQl().getPendingRequests(),
        _operationCoded('FORBIDDEN'),
      );
    });
  });

  group('completePendingRequest', () {
    const input = CompletePendingRequestInput(
      pendingQuestId: 'pq-story-1',
      outcomes: [ParticipantOverride(characterId: 'char-aldo', hpAfter: 12)],
    );

    test('sends CompletePendingRequest with the input variable', () async {
      handler = (_) => Stream.value(
        dataResponse({
          'completePendingRequest': [gmCompletedResultJson()],
        }),
      );

      await buildGraphQl().completePendingRequest(input);

      expect(operationNameOf(requests.single), 'CompletePendingRequest');
      expect(requests.single.variables, {'input': input.toJson()});
    });

    test('returns the created results, skipping a malformed one', () async {
      handler = (_) => Stream.value(
        dataResponse({
          'completePendingRequest': [
            gmCompletedResultJson(id: 'r-1'),
            {'id': 'broken'},
            gmCompletedResultJson(id: 'r-2'),
          ],
        }),
      );

      final results = await buildGraphQl().completePendingRequest(input);

      expect(results.map((result) => result.id), ['r-1', 'r-2']);
    });

    test('turns a payload that is not a list into a FormatException', () async {
      handler = (_) =>
          Stream.value(dataResponse({'completePendingRequest': null}));

      await expectLater(
        buildGraphQl().completePendingRequest(input),
        throwsFormatException,
      );
    });

    test('throws the raw OperationException keeping the code', () async {
      handler = (_) =>
          Stream.value(errorCodeResponse('OUTCOME_OVERRIDE_INVALID'));

      await expectLater(
        buildGraphQl().completePendingRequest(input),
        _operationCoded('OUTCOME_OVERRIDE_INVALID'),
      );
    });
  });
}
