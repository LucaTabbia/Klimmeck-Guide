import 'package:flutter_test/flutter_test.dart';
import 'package:gql/ast.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:klimmeck_guide/models/request/accept_quest_request.dart';
import 'package:klimmeck_guide/repository/services/graphql/graphql.dart';
import 'package:klimmeck_guide/repository/services/graphql/graphql_error_code.dart';

import '../../../helpers/fixtures/sync_event_fixtures.dart';

void main() {
  late List<Request> requests;
  late Stream<Response> Function(Request request) handler;

  const request = AcceptQuestRequest(id: 'c-1', questId: 'q-1');

  KlimmeckGraphQl buildGraphQl() => KlimmeckGraphQl(
    resolveClient: () => GraphQLClient(
      link: Link.function((incoming, [forward]) {
        requests.add(incoming);
        return handler(incoming);
      }),
      cache: GraphQLCache(store: InMemoryStore()),
    ),
  );

  setUp(() {
    requests = [];
    handler = (_) => Stream.value(dataResponse({}));
  });

  group('acceptQuest', () {
    test('sends the AcceptQuest operation with the request variable', () async {
      handler = (_) => Stream.value(
        dataResponse({
          'acceptQuest': {'response': 'Missione accettata', 'successful': true},
        }),
      );

      await buildGraphQl().acceptQuest(request);

      final operation = requests.single.operation.document.definitions
          .whereType<OperationDefinitionNode>()
          .first;
      expect(operation.name?.value, 'AcceptQuest');
      expect(requests.single.variables, {
        'request': {'id': 'c-1', 'questId': 'q-1'},
      });
    });

    test('completes when the backend answers successful', () async {
      handler = (_) => Stream.value(
        dataResponse({
          'acceptQuest': {'response': 'Missione accettata', 'successful': true},
        }),
      );

      await expectLater(buildGraphQl().acceptQuest(request), completes);
    });

    test('throws FormatException when successful is false', () async {
      handler = (_) => Stream.value(
        dataResponse({
          'acceptQuest': {'response': 'x', 'successful': false},
        }),
      );

      await expectLater(
        buildGraphQl().acceptQuest(request),
        throwsFormatException,
      );
    });

    test('throws FormatException when the payload is missing', () async {
      handler = (_) => Stream.value(dataResponse({'acceptQuest': null}));

      await expectLater(
        buildGraphQl().acceptQuest(request),
        throwsFormatException,
      );
    });

    test('throws the raw OperationException keeping the error code', () async {
      handler = (_) => Stream.value(errorCodeResponse('QUEST_FULL'));

      await expectLater(
        buildGraphQl().acceptQuest(request),
        throwsA(
          isA<OperationException>().having(
            graphQlErrorCode,
            'code',
            'QUEST_FULL',
          ),
        ),
      );
    });
  });
}
