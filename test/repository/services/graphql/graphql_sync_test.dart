import 'package:flutter_test/flutter_test.dart';
import 'package:gql/ast.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:klimmeck_guide/repository/services/graphql/graphql.dart';
import 'package:klimmeck_guide/repository/services/graphql/graphql_sync_exceptions.dart';

import '../../../helpers/fixtures/sync_event_fixtures.dart';

String? operationNameOf(Request request) => request
    .operation
    .document
    .definitions
    .whereType<OperationDefinitionNode>()
    .first
    .name
    ?.value;

Matcher _streamFailure(String operation, String? code) =>
    isA<SubscriptionStreamException>()
        .having((e) => e.operation, 'operation', operation)
        .having((e) => e.code, 'code', code);

Matcher _accessDenied(String code) => isA<GraphQlAccessDeniedException>()
    .having((e) => e.operation, 'operation', 'character')
    .having((e) => e.code, 'code', code);

Future<Object?> _errorOf(Future<Object?> future) async {
  try {
    await future;
    return null;
  } on Object catch (error) {
    return error;
  }
}

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

  group('subscribeToUser', () {
    test('sends OnUserChanged with no variables and emits the user', () async {
      handler = (_) => Stream.value(
        dataResponse({
          'userUpdated': userJson(
            twitchPoints: 5,
            role: 'innkeeper',
            characterId: 'c1',
          ),
        }),
      );

      final user = await buildGraphQl().subscribeToUser().first;

      expect(operationNameOf(requests.single), 'OnUserChanged');
      expect(requests.single.variables, isEmpty);
      expect(user.twitchPoints, 5);
      expect(user.role?.name, 'innkeeper');
      expect(user.currentCharacter?.id, 'c1');
    });

    test('emits successive events in order', () async {
      handler = (_) => Stream.fromIterable([
        dataResponse({'userUpdated': userJson(twitchPoints: 1)}),
        dataResponse({'userUpdated': userJson(twitchPoints: 2)}),
      ]);

      final points = await buildGraphQl()
          .subscribeToUser()
          .map((user) => user.twitchPoints)
          .toList();

      expect(points, [1, 2]);
    });

    test('turns a malformed payload into a FormatException', () {
      handler = (_) => Stream.value(malformedUserResponse());

      expect(
        buildGraphQl().subscribeToUser(),
        emitsInOrder([emitsError(isA<FormatException>()), emitsDone]),
      );
    });

    test('maps a FORBIDDEN rejection to a typed error, then completes', () {
      handler = (_) => Stream.value(errorCodeResponse('FORBIDDEN'));

      expect(
        buildGraphQl().subscribeToUser(),
        emitsInOrder([
          emitsError(_streamFailure('userUpdated', 'FORBIDDEN')),
          emitsDone,
        ]),
      );
    });
  });

  group('subscribeToCharacter', () {
    test(
      'sends characterUpdated with the id and emits the character',
      () async {
        handler = (_) => Stream.value(
          dataResponse({
            'characterUpdated': characterJson(id: 'c1', currentLifePoints: 4),
          }),
        );

        final character = await buildGraphQl().subscribeToCharacter('c1').first;

        expect(operationNameOf(requests.single), 'characterUpdated');
        expect(requests.single.variables, {'id': 'c1'});
        expect(character.status?.currentLifePoints, 4);
      },
    );

    test('maps FORBIDDEN to a typed error, then completes', () {
      handler = (_) => Stream.value(errorCodeResponse('FORBIDDEN'));

      expect(
        buildGraphQl().subscribeToCharacter('c1'),
        emitsInOrder([
          emitsError(_streamFailure('characterUpdated', 'FORBIDDEN')),
          emitsDone,
        ]),
      );
    });

    test('maps NOT_FOUND to a typed error', () {
      handler = (_) => Stream.value(errorCodeResponse('NOT_FOUND'));

      expect(
        buildGraphQl().subscribeToCharacter('c1'),
        emitsInOrder([
          emitsError(_streamFailure('characterUpdated', 'NOT_FOUND')),
          emitsDone,
        ]),
      );
    });

    test('turns a null character into a FormatException', () {
      handler = (_) => Stream.value(dataResponse({'characterUpdated': null}));

      expect(
        buildGraphQl().subscribeToCharacter('c1'),
        emitsInOrder([emitsError(isA<FormatException>()), emitsDone]),
      );
    });
  });

  group('getCharacter', () {
    test('throws the access denied exception on FORBIDDEN', () {
      handler = (_) => Stream.value(errorCodeResponse('FORBIDDEN'));

      expect(
        buildGraphQl().getCharacter('c1'),
        throwsA(_accessDenied('FORBIDDEN')),
      );
    });

    test('throws the access denied exception on NOT_FOUND', () {
      handler = (_) => Stream.value(errorCodeResponse('NOT_FOUND'));

      expect(
        buildGraphQl().getCharacter('c1'),
        throwsA(_accessDenied('NOT_FOUND')),
      );
    });

    test('keeps a plain exception for any other failure', () {
      handler = (_) => Stream.value(errorCodeResponse('INTERNAL_SERVER_ERROR'));

      expect(
        buildGraphQl().getCharacter('c1'),
        throwsA(
          allOf(isA<Exception>(), isNot(isA<GraphQlAccessDeniedException>())),
        ),
      );
    });
  });

  group('failures never expose payloads', () {
    test('typed errors print only operation and code', () async {
      handler = (_) => Stream.value(malformedUserResponse());
      final malformed = await _errorOf(buildGraphQl().subscribeToUser().first);
      handler = (_) => Stream.value(errorCodeResponse('FORBIDDEN'));
      final denied = await _errorOf(buildGraphQl().getCharacter('c1'));

      for (final error in [malformed, denied]) {
        expect(error, isNotNull);
        expect(error.toString(), isNot(contains('twitch')));
        expect(error.toString(), isNot(contains('{')));
      }
    });
  });
}
