import 'package:gql_exec/gql_exec.dart';
import 'package:gql_link/gql_link.dart';
import 'package:klimmeck_guide/repository/services/auth/auth_token_service.dart';

/// GraphQL Link che inietta il token OAuth nell'header `Authorization`.
///
/// Aggiunge `Authorization: Bearer <token>` al context `HttpLinkHeaders`
/// di ogni request HTTP quando il token è disponibile. Le subscription WS
/// ricevono il token tramite `initialPayload` al setup del `WebSocketLink`
/// (vedi `graphql_client_provider.dart`).
///
/// Phase 11 (D-07 auth-session-bootstrap/11-CONTEXT.md): ricreazione del
/// link on-demand su refresh token. In Phase 1 il token è statico — il
/// link viene costruito una volta al boot.
///
/// Fail-open: se `getAccessToken()` lancia, la request procede senza header
/// (coerente con la regola "no loading bloccante in sessione attiva").
class AuthAuthLink extends Link {
  AuthAuthLink({required AuthTokenService authService})
      : _authService = authService;

  final AuthTokenService _authService;

  @override
  Stream<Response> request(Request request, [NextLink? forward]) async* {
    String? token;
    try {
      token = await _authService.getAccessToken();
    } catch (_) {
      // fail-open: token rimane null
    }

    final Request updated;
    if (token != null && token.isNotEmpty) {
      updated = request.updateContextEntry<HttpLinkHeaders>(
        (prev) => HttpLinkHeaders(
          headers: {
            ...?prev?.headers,
            'Authorization': 'Bearer $token',
          },
        ),
      );
    } else {
      updated = request;
    }

    yield* forward!(updated);
  }
}
