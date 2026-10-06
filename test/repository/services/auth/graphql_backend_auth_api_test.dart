import 'package:flutter_test/flutter_test.dart';
import 'package:gql_exec/gql_exec.dart';
import 'package:gql_link/gql_link.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:klimmeck_guide/repository/services/auth/auth_api_exception.dart';
import 'package:klimmeck_guide/repository/services/auth/graphql_backend_auth_api.dart';

import '../../../helpers/auth_fixtures.dart';
import '../../../helpers/auth_session_fixtures.dart';

typedef _Handler = Stream<Response> Function(Request request);

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

  Stream<Response> gqlError(String code) => Stream.value(
    Response(
      response: const {},
      errors: [
        GraphQLError(message: 'x', extensions: {'code': code}),
      ],
    ),
  );

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
        expect(request.operation.operationName, 'ExchangeLoginTicket');
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
      expect(request.operation.operationName, 'RefreshSession');
      expect(request.variables, {'refreshToken': 'r'});
      expect(request.context.entry<HttpLinkHeaders>(), isNull);
      expect(session.refreshToken, 'r');
    });

    test('logout sends the bearer header', () async {
      handler = (_) => data({'logout': true});

      await buildApi().logout('acc');

      final request = requests.single;
      expect(request.operation.operationName, 'Logout');
      expect(request.context.entry<HttpLinkHeaders>()?.headers, {
        'Authorization': 'Bearer acc',
      });
    });

    test('fetchMe sends the bearer header and parses the user', () async {
      handler = (_) => data({'me': meJson()});

      final user = await buildApi().fetchMe('acc');

      final request = requests.single;
      expect(request.operation.operationName, 'GetMe');
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
        NetworkException(uri: Uri(), originalException: null, message: 'down'),
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
