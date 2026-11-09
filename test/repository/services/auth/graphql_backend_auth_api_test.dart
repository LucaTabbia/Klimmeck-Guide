import 'package:flutter_test/flutter_test.dart';
import 'package:gql/ast.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:klimmeck_guide/repository/services/auth/auth_api_exception.dart';
import 'package:klimmeck_guide/repository/services/auth/graphql_backend_auth_api.dart';

import '../../../helpers/auth_fixtures.dart';
import '../../../helpers/auth_session_fixtures.dart';

String? operationNameOf(Request request) => request
    .operation
    .document
    .definitions
    .whereType<OperationDefinitionNode>()
    .first
    .name
    ?.value;

typedef _Handler = Stream<Response> Function(Request request);

const Object _noReason = Object();

void main() {
  late List<Request> requests;
  late _Handler handler;

  GraphQlBackendAuthApi buildApi() => GraphQlBackendAuthApi(
    client: GraphQLClient(
      link: Link.function((request, [forward]) {
        requests.add(request);
        return handler(request);
      }),
      cache: GraphQLCache(store: InMemoryStore()),
    ),
  );

  Stream<Response> data(Map<String, dynamic> data) =>
      Stream.value(Response(response: {'data': data}, data: data));

  Stream<Response> gqlErrors(List<GraphQLError> errors) =>
      Stream.value(Response(response: const {}, errors: errors));

  GraphQLError codedError(String code, {Object? reason = _noReason}) =>
      GraphQLError(
        message: 'x',
        extensions: {'code': code, if (reason != _noReason) 'reason': reason},
      );

  Stream<Response> gqlError(String code, {Object? reason = _noReason}) =>
      gqlErrors([codedError(code, reason: reason)]);

  setUp(() {
    requests = [];
    handler = (_) => data({});
  });

  Map<String, dynamic> meJson() =>
      (authSessionJson()['user'] as Map<String, dynamic>);

  group('success paths', () {
    test(
      'exchangeLoginTicket sends variables and parses the session',
      () async {
        handler = (_) => data({'exchangeLoginTicket': authSessionJson()});

        final session = await buildApi().exchangeLoginTicket(
          ticket: 't',
          codeVerifier: 'v',
        );

        final request = requests.single;
        expect(operationNameOf(request), 'ExchangeLoginTicket');
        expect(request.variables, {'ticket': 't', 'codeVerifier': 'v'});
        expect(request.context.entry<HttpLinkHeaders>(), isNull);
        expect(session.accessToken, 'a');
        expect(session.user.id, testUserId);
      },
    );

    test('refreshSession sends the refresh token without bearer', () async {
      handler = (_) => data({'refreshSession': authSessionJson()});

      final session = await buildApi().refreshSession('r');

      final request = requests.single;
      expect(operationNameOf(request), 'RefreshSession');
      expect(request.variables, {'refreshToken': 'r'});
      expect(request.context.entry<HttpLinkHeaders>(), isNull);
      expect(session.refreshToken, 'r');
    });

    test('logout sends the bearer header', () async {
      handler = (_) => data({'logout': true});

      await buildApi().logout('acc');

      final request = requests.single;
      expect(operationNameOf(request), 'Logout');
      expect(request.context.entry<HttpLinkHeaders>()?.headers, {
        'Authorization': 'Bearer acc',
      });
    });

    test('fetchMe sends the bearer header and parses the user', () async {
      handler = (_) => data({'me': meJson()});

      final user = await buildApi().fetchMe('acc');

      final request = requests.single;
      expect(operationNameOf(request), 'GetMe');
      expect(request.context.entry<HttpLinkHeaders>()?.headers, {
        'Authorization': 'Bearer acc',
      });
      expect(user.id, testUserId);
    });
  });

  group('refreshSession error mapping', () {
    for (final code in ['SESSION_EXPIRED', 'SESSION_REVOKED']) {
      test('$code is terminal', () async {
        handler = (_) => gqlError(code);

        await expectLater(
          buildApi().refreshSession('r'),
          throwsA(SessionRejected(code)),
        );
      });
    }

    test('SESSION_REVOKED carries the newLogin reason (D-12)', () async {
      handler = (_) => gqlError('SESSION_REVOKED', reason: 'newLogin');

      await expectLater(
        buildApi().refreshSession('r'),
        throwsA(const SessionRejected('SESSION_REVOKED', reason: 'newLogin')),
      );
    });

    test('SESSION_REVOKED carries the roleChanged reason (D-12)', () async {
      handler = (_) => gqlError('SESSION_REVOKED', reason: 'roleChanged');

      await expectLater(
        buildApi().refreshSession('r'),
        throwsA(
          const SessionRejected('SESSION_REVOKED', reason: 'roleChanged'),
        ),
      );
    });

    test('SESSION_REVOKED keeps an unknown reason string (D-12)', () async {
      handler = (_) => gqlError('SESSION_REVOKED', reason: 'somethingNew');

      await expectLater(
        buildApi().refreshSession('r'),
        throwsA(
          const SessionRejected('SESSION_REVOKED', reason: 'somethingNew'),
        ),
      );
    });

    test(
      'SESSION_REVOKED with a non-string or empty reason has no reason (D-12)',
      () async {
        for (final reason in <Object>[42, '']) {
          handler = (_) => gqlError('SESSION_REVOKED', reason: reason);

          await expectLater(
            buildApi().refreshSession('r'),
            throwsA(const SessionRejected('SESSION_REVOKED')),
          );
        }
      },
    );

    test('SESSION_EXPIRED never carries a reason (D-12)', () async {
      handler = (_) => gqlError('SESSION_EXPIRED', reason: 'newLogin');

      await expectLater(
        buildApi().refreshSession('r'),
        throwsA(const SessionRejected('SESSION_EXPIRED')),
      );
    });

    test(
      'the reason comes from the error that carried the code (D-12)',
      () async {
        handler = (_) => gqlErrors([
          GraphQLError(message: 'x', extensions: const {'reason': 'newLogin'}),
          codedError('SESSION_REVOKED'),
        ]);

        await expectLater(
          buildApi().refreshSession('r'),
          throwsA(const SessionRejected('SESSION_REVOKED')),
        );
      },
    );

    test('UNAUTHENTICATED is transient', () async {
      handler = (_) => gqlError('UNAUTHENTICATED');

      await expectLater(
        buildApi().refreshSession('r'),
        throwsA(const TransientAuthFailure('UNAUTHENTICATED')),
      );
    });

    test('BAD_REQUEST is transient', () async {
      handler = (_) => gqlError('BAD_REQUEST');

      await expectLater(
        buildApi().refreshSession('r'),
        throwsA(const TransientAuthFailure('BAD_REQUEST')),
      );
    });

    test('HTTP 401 is transient', () async {
      handler = (_) => Stream.error(
        const ServerException(
          statusCode: 401,
          parsedResponse: null,
          originalException: null,
        ),
      );

      await expectLater(
        buildApi().refreshSession('r'),
        throwsA(isA<TransientAuthFailure>()),
      );
    });

    test('unknown code is transient', () async {
      handler = (_) => gqlError('WHATEVER');

      await expectLater(
        buildApi().refreshSession('r'),
        throwsA(const TransientAuthFailure('WHATEVER')),
      );
    });

    test('network failure and HTTP 500 are transient', () async {
      handler = (_) => Stream.error(
        NetworkException(
          uri: Uri(),
          originalException: Exception('down'),
          message: 'down',
        ),
      );
      await expectLater(
        buildApi().refreshSession('r'),
        throwsA(isA<TransientAuthFailure>()),
      );

      handler = (_) => Stream.error(
        const ServerException(
          statusCode: 500,
          parsedResponse: null,
          originalException: null,
        ),
      );
      await expectLater(
        buildApi().refreshSession('r'),
        throwsA(isA<TransientAuthFailure>()),
      );
    });

    test('malformed payload is transient malformed_response', () async {
      final broken = authSessionJson()..remove('accessTokenExpiresAt');
      handler = (_) => data({'refreshSession': broken});

      await expectLater(
        buildApi().refreshSession('r'),
        throwsA(const TransientAuthFailure('malformed_response')),
      );
    });
  });

  group('other operations error mapping', () {
    test('LOGIN_TICKET_INVALID on exchange', () async {
      handler = (_) => gqlError('LOGIN_TICKET_INVALID');

      await expectLater(
        buildApi().exchangeLoginTicket(ticket: 't', codeVerifier: 'v'),
        throwsA(const LoginTicketInvalid()),
      );
    });

    test('UNAUTHENTICATED on logout and fetchMe', () async {
      handler = (_) => gqlError('UNAUTHENTICATED');

      await expectLater(
        buildApi().logout('acc'),
        throwsA(const AccessTokenRejected()),
      );
      await expectLater(
        buildApi().fetchMe('acc'),
        throwsA(const AccessTokenRejected()),
      );
    });

    test('HTTP 401 on logout and fetchMe', () async {
      handler = (_) => Stream.error(
        const ServerException(
          statusCode: 401,
          parsedResponse: null,
          originalException: null,
        ),
      );

      await expectLater(
        buildApi().logout('acc'),
        throwsA(const AccessTokenRejected()),
      );
      await expectLater(
        buildApi().fetchMe('acc'),
        throwsA(const AccessTokenRejected()),
      );
    });

    test('INTERNAL_SERVER_ERROR is transient', () async {
      handler = (_) => gqlError('INTERNAL_SERVER_ERROR');

      await expectLater(
        buildApi().fetchMe('acc'),
        throwsA(isA<TransientAuthFailure>()),
      );
    });
  });
}
