import 'package:flutter_test/flutter_test.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:klimmeck_guide/repository/services/graphql/graphql.dart';
import 'package:klimmeck_guide/repository/services/graphql/graphql_error_code.dart';

import '../../../helpers/fixtures/sync_event_fixtures.dart';
import 'graphql_sync_test.dart' show operationNameOf;

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

  group('generateQuests', () {
    test('sends GenerateQuests and returns created (D-10)', () async {
      handler = (_) => Stream.value(
        dataResponse({
          'generateQuests': {'created': 3},
        }),
      );

      final created = await buildGraphQl().generateQuests();

      expect(operationNameOf(requests.single), 'GenerateQuests');
      expect(requests.single.variables, isEmpty);
      expect(created, 3);
    });

    test('returns 0 when the world is full (D-09)', () async {
      handler = (_) => Stream.value(
        dataResponse({
          'generateQuests': {'created': 0},
        }),
      );

      expect(await buildGraphQl().generateQuests(), 0);
    });

    test('throws FormatException when created is missing (D-10)', () async {
      for (final payload in <Object?>[<String, dynamic>{}, null]) {
        handler = (_) =>
            Stream.value(dataResponse({'generateQuests': payload}));

        await expectLater(
          buildGraphQl().generateQuests(),
          throwsFormatException,
        );
      }
    });

    test(
      'surfaces FORBIDDEN as an OperationException carrying the code (D-09)',
      () async {
        handler = (_) => Stream.value(errorCodeResponse('FORBIDDEN'));

        await expectLater(
          buildGraphQl().generateQuests(),
          throwsA(
            isA<OperationException>().having(
              graphQlErrorCode,
              'code',
              'FORBIDDEN',
            ),
          ),
        );
      },
    );
  });
}
