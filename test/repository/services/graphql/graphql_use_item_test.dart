import 'package:flutter_test/flutter_test.dart';
import 'package:gql/ast.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:klimmeck_guide/repository/services/graphql/graphql.dart';
import 'package:klimmeck_guide/repository/services/graphql/graphql_error_code.dart';

import '../../../helpers/fixtures/potion_fixtures.dart';
import '../../../helpers/fixtures/sync_event_fixtures.dart';

void main() {
  late List<Request> requests;
  late Stream<Response> Function(Request request) handler;

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
    handler = (_) =>
        Stream.value(dataResponse({'useItem': useItemResultJson()}));
  });

  group('useItem', () {
    test('sends UseItem with the item id only (D-11)', () async {
      await buildGraphQl().useItem('l-herb');

      final operation = requests.single.operation.document.definitions
          .whereType<OperationDefinitionNode>()
          .first;
      expect(operation.name?.value, 'UseItem');
      expect(requests.single.variables, {'itemId': 'l-herb'});
    });

    test('returns the parsed UseItemResult (D-11)', () async {
      final result = await buildGraphQl().useItem('l-herb');

      expect(result.hpAfter, 8);
      expect(result.recoveryUntil, DateTime.utc(2026, 10, 27, 10, 30));
    });

    test('a refusal throws its OperationException (D-11)', () async {
      handler = (_) => Stream.value(errorCodeResponse('POTION_RECOVERING'));

      await expectLater(
        buildGraphQl().useItem('l-herb'),
        throwsA(
          isA<OperationException>().having(
            graphQlErrorCode,
            'code',
            'POTION_RECOVERING',
          ),
        ),
      );
    });

    test('a malformed answer throws a FormatException (D-11)', () async {
      for (final answer in <Object?>[
        null,
        {'hpBefore': 1},
      ]) {
        handler = (_) => Stream.value(dataResponse({'useItem': answer}));

        await expectLater(
          buildGraphQl().useItem('l-herb'),
          throwsFormatException,
          reason: '$answer',
        );
      }
    });
  });
}
