import 'package:flutter_test/flutter_test.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:klimmeck_guide/models/quest_result/quest_outcome.dart';
import 'package:klimmeck_guide/models/quest_result/quest_result.dart';
import 'package:klimmeck_guide/repository/services/graphql/graphql.dart';
import 'package:klimmeck_guide/repository/services/graphql/graphql_error_code.dart';
import 'package:klimmeck_guide/repository/services/graphql/graphql_sync_exceptions.dart';

import '../../../helpers/fixtures/quest_result_fixtures.dart';
import '../../../helpers/fixtures/sync_event_fixtures.dart';
import 'graphql_sync_test.dart' show operationNameOf;

Matcher _streamFailure(String code) => isA<SubscriptionStreamException>()
    .having((e) => e.operation, 'operation', 'questResultReceived')
    .having((e) => e.code, 'code', code);

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

  group('subscribeToQuestResults', () {
    test(
      'sends OnQuestResultReceived and emits the results in order',
      () async {
        handler = (_) => Stream.fromIterable([
          dataResponse({'questResultReceived': successResultJson()}),
          dataResponse({'questResultReceived': deathResultJson()}),
        ]);

        final outcomes = await buildGraphQl()
            .subscribeToQuestResults('c-1')
            .map((result) => result.outcome)
            .toList();

        expect(operationNameOf(requests.single), 'OnQuestResultReceived');
        expect(requests.single.variables, {'characterId': 'c-1'});
        expect(outcomes, [QuestOutcome.success, QuestOutcome.death]);
      },
    );

    test('maps NOT_FOUND to a typed stream error', () {
      handler = (_) => Stream.value(errorCodeResponse('NOT_FOUND'));

      expect(
        buildGraphQl().subscribeToQuestResults('c-1'),
        emitsInOrder([emitsError(_streamFailure('NOT_FOUND')), emitsDone]),
      );
    });

    test('keeps delivering after a malformed event', () {
      handler = (_) => Stream.fromIterable([
        dataResponse({
          'questResultReceived': {'id': 'x'},
        }),
        dataResponse({'questResultReceived': successResultJson()}),
      ]);

      expect(
        buildGraphQl().subscribeToQuestResults('c-1'),
        emitsInOrder([
          emitsError(isA<FormatException>()),
          isA<QuestResult>().having((result) => result.id, 'id', 'result-1'),
          emitsDone,
        ]),
      );
    });
  });

  group('getQuestResult', () {
    test('sends GetQuestResult with the id and returns the result', () async {
      handler = (_) =>
          Stream.value(dataResponse({'questResult': successResultJson()}));

      final result = await buildGraphQl().getQuestResult('result-1');

      expect(operationNameOf(requests.single), 'GetQuestResult');
      expect(requests.single.variables, {'id': 'result-1'});
      expect(result, questResult(successResultJson()));
    });

    test('throws the raw OperationException keeping the code', () async {
      handler = (_) => Stream.value(errorCodeResponse('FORBIDDEN'));

      await expectLater(
        buildGraphQl().getQuestResult('result-1'),
        throwsA(
          isA<OperationException>().having(
            graphQlErrorCode,
            'code',
            'FORBIDDEN',
          ),
        ),
      );
    });

    test('turns a missing result into a FormatException', () async {
      handler = (_) => Stream.value(dataResponse({'questResult': null}));

      await expectLater(
        buildGraphQl().getQuestResult('result-1'),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('getUnacknowledgedQuestResults', () {
    test(
      'sends ListUnacknowledgedQuestResults and keeps the server order',
      () async {
        handler = (_) => Stream.value(
          dataResponse({
            'unacknowledgedQuestResults': [
              failureResultJson(id: 'r-1'),
              deathResultJson(id: 'r-2'),
            ],
          }),
        );

        final results = await buildGraphQl().getUnacknowledgedQuestResults();

        expect(
          operationNameOf(requests.single),
          'ListUnacknowledgedQuestResults',
        );
        expect(requests.single.variables, isEmpty);
        expect(results.map((result) => result.id), ['r-1', 'r-2']);
      },
    );

    test('skips a malformed entry and keeps the valid ones', () async {
      handler = (_) => Stream.value(
        dataResponse({
          'unacknowledgedQuestResults': [
            {'id': 'broken'},
            successResultJson(id: 'r-2'),
          ],
        }),
      );

      final results = await buildGraphQl().getUnacknowledgedQuestResults();

      expect(results.map((result) => result.id), ['r-2']);
    });

    test('returns an empty list when nothing is pending', () async {
      handler = (_) =>
          Stream.value(dataResponse({'unacknowledgedQuestResults': []}));

      expect(await buildGraphQl().getUnacknowledgedQuestResults(), isEmpty);
    });

    test('turns a payload that is not a list into a FormatException', () async {
      handler = (_) =>
          Stream.value(dataResponse({'unacknowledgedQuestResults': null}));

      await expectLater(
        buildGraphQl().getUnacknowledgedQuestResults(),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws the raw OperationException keeping the code', () async {
      handler = (_) => Stream.value(errorCodeResponse('UNAUTHENTICATED'));

      await expectLater(
        buildGraphQl().getUnacknowledgedQuestResults(),
        throwsA(
          isA<OperationException>().having(
            graphQlErrorCode,
            'code',
            'UNAUTHENTICATED',
          ),
        ),
      );
    });
  });

  group('acknowledgeQuestResult', () {
    Response acknowledged({required bool successful}) => dataResponse({
      'acknowledgeQuestResult': {
        'successful': successful,
        'response': 'Risultato confermato',
      },
    });

    test('sends AcknowledgeQuestResult with the id', () async {
      handler = (_) => Stream.value(acknowledged(successful: true));

      await buildGraphQl().acknowledgeQuestResult('r-1');

      expect(operationNameOf(requests.single), 'AcknowledgeQuestResult');
      expect(requests.single.variables, {'id': 'r-1'});
    });

    test('turns an unsuccessful answer into a FormatException', () async {
      handler = (_) => Stream.value(acknowledged(successful: false));

      await expectLater(
        buildGraphQl().acknowledgeQuestResult('r-1'),
        throwsA(isA<FormatException>()),
      );
    });

    test('turns a missing payload into a FormatException', () async {
      handler = (_) =>
          Stream.value(dataResponse({'acknowledgeQuestResult': null}));

      await expectLater(
        buildGraphQl().acknowledgeQuestResult('r-1'),
        throwsA(isA<FormatException>()),
      );
    });

    for (final code in ['NOT_FOUND', 'FORBIDDEN']) {
      test('throws the raw OperationException for $code', () async {
        handler = (_) => Stream.value(errorCodeResponse(code));

        await expectLater(
          buildGraphQl().acknowledgeQuestResult('r-1'),
          throwsA(
            isA<OperationException>().having(graphQlErrorCode, 'code', code),
          ),
        );
      });
    }
  });
}
