import 'package:flutter_test/flutter_test.dart';
import 'package:gql/ast.dart';
import 'package:gql_exec/gql_exec.dart';
import 'package:gql_http_link/gql_http_link.dart';
import 'package:gql_link/gql_link.dart';
import 'package:klimmeck_guide/repository/services/auth/auth_token_service.dart';
import 'package:klimmeck_guide/repository/services/graphql/auth_link.dart';
import 'package:mocktail/mocktail.dart';

/// RED — GraphQL AuthLink (DEV-AUTH-05).
/// Diventerà GREEN dopo Plan 03.
class MockAuthTokenService extends Mock implements AuthTokenService {}

void main() {
  late MockAuthTokenService mockService;
  late AuthAuthLink authLink;

  setUp(() {
    mockService = MockAuthTokenService();
    authLink = AuthAuthLink(authService: mockService);
  });

  group('AuthAuthLink (GraphQL)', () {
    test(
      'aggiunge Authorization: Bearer <token> agli header della Request',
      () async {
        when(() => mockService.getAccessToken())
            .thenAnswer((_) async => 'token-xyz');

        // Richiesta GraphQL minimale.
        final request = Request(
          operation: Operation(document: DocumentNode(definitions: const [])),
        );

        HttpLinkHeaders? capturedHeaders;

        // Link terminale che cattura gli header.
        final terminalLink = Link.function((req, [nextLink]) async* {
          capturedHeaders = req.context.entry<HttpLinkHeaders>();
          yield const Response(response: {'data': null});
        });

        final linked = Link.concat(authLink, terminalLink);
        await linked.request(request).first;

        expect(
          capturedHeaders?.headers['Authorization'],
          equals('Bearer token-xyz'),
        );
      },
    );
  });
}
