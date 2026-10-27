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
}
