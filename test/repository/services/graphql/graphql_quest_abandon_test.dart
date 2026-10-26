import 'package:flutter_test/flutter_test.dart';
import 'package:gql/ast.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:klimmeck_guide/models/request/abandon_quest_request.dart';
import 'package:klimmeck_guide/repository/services/graphql/graphql.dart';
import 'package:klimmeck_guide/repository/services/graphql/graphql_error_code.dart';

import '../../../helpers/fixtures/sync_event_fixtures.dart';

void main() {
  late List<Request> requests;
  late Stream<Response> Function(Request request) handler;

  const request = AbandonQuestRequest(id: 'c-1', questId: 'q-1');

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

  group('abandonQuest', () {
    test(
      'sends the AbandonQuest operation with the request variable',
      () async {
        handler = (_) => Stream.value(
          dataResponse({
            'abandonQuest': {'successful': true},
          }),
        );

        await buildGraphQl().abandonQuest(request);

        final operation = requests.single.operation.document.definitions
            .whereType<OperationDefinitionNode>()
            .first;
        expect(operation.name?.value, 'AbandonQuest');
        expect(requests.single.variables, {
          'request': {'id': 'c-1', 'questId': 'q-1'},
        });
      },
    );

    test('throws FormatException when successful is false', () async {
      handler = (_) => Stream.value(
        dataResponse({
          'abandonQuest': {'successful': false},
        }),
      );

      await expectLater(
        buildGraphQl().abandonQuest(request),
        throwsFormatException,
      );
    });

    test('throws FormatException when the payload is missing', () async {
      handler = (_) => Stream.value(dataResponse({'abandonQuest': null}));

      await expectLater(
        buildGraphQl().abandonQuest(request),
        throwsFormatException,
      );
    });

    test('throws the raw OperationException keeping the error code', () async {
      handler = (_) => Stream.value(errorCodeResponse('QUEST_NOT_WAITING'));

      await expectLater(
        buildGraphQl().abandonQuest(request),
        throwsA(
          isA<OperationException>().having(
            graphQlErrorCode,
            'code',
            'QUEST_NOT_WAITING',
          ),
        ),
      );
    });
  });
}
