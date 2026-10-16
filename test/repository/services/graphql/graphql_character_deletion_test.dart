import 'package:flutter_test/flutter_test.dart';
import 'package:gql/ast.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:klimmeck_guide/repository/services/graphql/graphql.dart';
import 'package:klimmeck_guide/repository/services/graphql/graphql_error_code.dart';

import '../../../helpers/auth_fixtures.dart';
import '../../../helpers/fixtures/sync_event_fixtures.dart';

String? operationNameOf(Request request) => request
    .operation
    .document
    .definitions
    .whereType<OperationDefinitionNode>()
    .first
    .name
    ?.value;

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
    handler = (_) => Stream.value(dataResponse({}));
  });

  group('deleteCharacter', () {
    test('sends the DeleteCharacter operation without variables', () async {
      handler = (_) =>
          Stream.value(dataResponse({'deleteCharacter': userJson()}));

      await buildGraphQl().deleteCharacter();

      expect(operationNameOf(requests.single), 'DeleteCharacter');
      expect(requests.single.variables, isEmpty);
    });

    test('returns the user without a current character', () async {
      handler = (_) =>
          Stream.value(dataResponse({'deleteCharacter': userJson()}));

      final user = await buildGraphQl().deleteCharacter();

      expect(user.id, testUserId);
      expect(user.currentCharacter, isNull);
    });

    test('throws the raw OperationException keeping the error code', () async {
      handler = (_) => Stream.value(errorCodeResponse('CHARACTER_NOT_FOUND'));

      await expectLater(
        buildGraphQl().deleteCharacter(),
        throwsA(
          isA<OperationException>().having(
            graphQlErrorCode,
            'code',
            'CHARACTER_NOT_FOUND',
          ),
        ),
      );
    });

    test('throws FormatException when the user is missing', () async {
      handler = (_) => Stream.value(dataResponse({'deleteCharacter': null}));

      await expectLater(
        buildGraphQl().deleteCharacter(),
        throwsFormatException,
      );
    });

    test('throws FormatException when the user is malformed', () async {
      handler = (_) => Stream.value(
        dataResponse({
          'deleteCharacter': {'id': 42},
        }),
      );

      await expectLater(
        buildGraphQl().deleteCharacter(),
        throwsFormatException,
      );
    });
  });
}
