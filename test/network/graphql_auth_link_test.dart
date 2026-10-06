import 'package:flutter_test/flutter_test.dart';
import 'package:gql/ast.dart';
import 'package:gql_exec/gql_exec.dart';
import 'package:gql_link/gql_link.dart';
import 'package:klimmeck_guide/repository/services/graphql/auth_link.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/mocks.dart';

const _unauthenticated = Response(
  response: {'data': null},
  errors: [
    GraphQLError(
      message: 'Unauthorized',
      extensions: {'code': 'UNAUTHENTICATED'},
    ),
  ],
);
const _ok = Response(response: {'data': {}}, data: {});

Request _request() => Request(
  operation: Operation(document: DocumentNode(definitions: const [])),
);

void main() {
  late MockAuthTokenService mockService;
  late MockUnauthorizedRecovery mockRecovery;
  late List<String?> sentAuthorizations;

  setUp(() {
    mockService = MockAuthTokenService();
    mockRecovery = MockUnauthorizedRecovery();
    sentAuthorizations = [];
    when(() => mockService.getAccessToken()).thenAnswer((_) async => 'A1');
  });

  Link terminal(Response Function(String? authorization) answer) =>
      Link.function((req, [nextLink]) async* {
        final authorization = req.context
            .entry<HttpLinkHeaders>()
            ?.headers['Authorization'];
        sentAuthorizations.add(authorization);
        yield answer(authorization);
      });

  Link buildLink(Link end, {bool withRecovery = true}) => Link.concat(
    AuthAuthLink(
      authService: mockService,
      recovery: withRecovery ? mockRecovery : null,
    ),
    end,
  );

  group('AuthAuthLink (GraphQL)', () {
    test('adds Authorization: Bearer <token> to the request headers', () async {
      when(
        () => mockService.getAccessToken(),
      ).thenAnswer((_) async => 'token-xyz');
      final link = buildLink(terminal((_) => _ok));

      await link.request(_request()).first;

      expect(sentAuthorizations, ['Bearer token-xyz']);
    });

    test('retries once with the new token after UNAUTHENTICATED', () async {
      when(
        () => mockRecovery.recoverFromUnauthorized(rejectedToken: 'A1'),
      ).thenAnswer((_) async => 'A2');
      final link = buildLink(
        terminal((auth) => auth == 'Bearer A2' ? _ok : _unauthenticated),
      );

      final responses = await link.request(_request()).toList();

      expect(responses, [_ok]);
      expect(sentAuthorizations, ['Bearer A1', 'Bearer A2']);
      verify(
        () => mockRecovery.recoverFromUnauthorized(rejectedToken: 'A1'),
      ).called(1);
    });

    test(
      'does not retry a second time when the retry is rejected too',
      () async {
        when(
          () => mockRecovery.recoverFromUnauthorized(rejectedToken: 'A1'),
        ).thenAnswer((_) async => 'A2');
        final link = buildLink(terminal((_) => _unauthenticated));

        final responses = await link.request(_request()).toList();

        expect(responses, [_unauthenticated]);
        expect(sentAuthorizations, ['Bearer A1', 'Bearer A2']);
        verify(
          () => mockRecovery.recoverFromUnauthorized(
            rejectedToken: any(named: 'rejectedToken'),
          ),
        ).called(1);
      },
    );

    test('returns the original response when recovery yields null', () async {
      when(
        () => mockRecovery.recoverFromUnauthorized(rejectedToken: 'A1'),
      ).thenAnswer((_) async => null);
      final link = buildLink(terminal((_) => _unauthenticated));

      final responses = await link.request(_request()).toList();

      expect(responses, [_unauthenticated]);
      expect(sentAuthorizations, ['Bearer A1']);
    });

    test('does not retry when built without recovery', () async {
      final link = buildLink(
        terminal((_) => _unauthenticated),
        withRecovery: false,
      );

      final responses = await link.request(_request()).toList();

      expect(responses, [_unauthenticated]);
      expect(sentAuthorizations, ['Bearer A1']);
    });

    test('does not retry a request that was sent without a token', () async {
      when(() => mockService.getAccessToken()).thenAnswer((_) async => null);
      final link = buildLink(terminal((_) => _unauthenticated));

      final responses = await link.request(_request()).toList();

      expect(responses, [_unauthenticated]);
      expect(sentAuthorizations, [null]);
      verifyNever(
        () => mockRecovery.recoverFromUnauthorized(
          rejectedToken: any(named: 'rejectedToken'),
        ),
      );
    });

    test('never calls recovery for a successful response', () async {
      final link = buildLink(terminal((_) => _ok));

      await link.request(_request()).toList();

      verifyNever(
        () => mockRecovery.recoverFromUnauthorized(
          rejectedToken: any(named: 'rejectedToken'),
        ),
      );
    });

    test(
      'retries once when the transport throws ServerException 401',
      () async {
        when(
          () => mockRecovery.recoverFromUnauthorized(rejectedToken: 'A1'),
        ).thenAnswer((_) async => 'A2');
        final link = Link.concat(
          AuthAuthLink(authService: mockService, recovery: mockRecovery),
          Link.function((req, [nextLink]) async* {
            final authorization = req.context
                .entry<HttpLinkHeaders>()
                ?.headers['Authorization'];
            sentAuthorizations.add(authorization);
            if (authorization == 'Bearer A2') {
              yield _ok;
              return;
            }
            throw const ServerException(statusCode: 401, parsedResponse: null);
          }),
        );

        final responses = await link.request(_request()).toList();

        expect(responses, [_ok]);
        expect(sentAuthorizations, ['Bearer A1', 'Bearer A2']);
      },
    );

    test('rethrows ServerException 500 without retrying', () async {
      final link = Link.concat(
        AuthAuthLink(authService: mockService, recovery: mockRecovery),
        Link.function((req, [nextLink]) async* {
          sentAuthorizations.add('sent');
          throw const ServerException(statusCode: 500, parsedResponse: null);
        }),
      );

      await expectLater(
        link.request(_request()).toList(),
        throwsA(isA<ServerException>()),
      );
      expect(sentAuthorizations, ['sent']);
      verifyNever(
        () => mockRecovery.recoverFromUnauthorized(
          rejectedToken: any(named: 'rejectedToken'),
        ),
      );
    });

    test(
      'rethrows the original ServerException 401 when recovery yields null',
      () async {
        when(
          () => mockRecovery.recoverFromUnauthorized(rejectedToken: 'A1'),
        ).thenAnswer((_) async => null);
        final link = Link.concat(
          AuthAuthLink(authService: mockService, recovery: mockRecovery),
          Link.function((req, [nextLink]) async* {
            throw const ServerException(statusCode: 401, parsedResponse: null);
          }),
        );

        await expectLater(
          link.request(_request()).toList(),
          throwsA(isA<ServerException>()),
        );
      },
    );
  });
}
