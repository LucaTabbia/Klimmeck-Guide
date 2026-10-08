import 'package:gql_exec/gql_exec.dart';
import 'package:gql_link/gql_link.dart';
import 'package:klimmeck_guide/repository/services/auth/auth_token_service.dart';
import 'package:klimmeck_guide/repository/services/auth/unauthorized_recovery.dart';

/// Marca una richiesta già ritentata dopo un rifiuto di autenticazione:
/// garantisce un solo retry.
class AuthRetried extends ContextEntry {
  const AuthRetried();

  @override
  List<Object?> get fieldsForEquality => const [];
}

/// GraphQL Link che inietta il token OAuth nell'header `Authorization` e
/// ritenta UNA volta dopo un rifiuto di autenticazione.
///
/// Aggiunge `Authorization: Bearer <token>` al context `HttpLinkHeaders`
/// di ogni request HTTP quando il token è disponibile.
///
/// Se il backend risponde `UNAUTHENTICATED` (o il trasporto lancia una
/// `ServerException` 401) e il link ha una [UnauthorizedRecovery], la
/// richiesta viene rinviata una sola volta col token rinnovato. Se la
/// recovery non produce un token, il chiamante riceve la risposta (o
/// l'eccezione) originale. Una richiesta inviata senza token non viene
/// ritentata.
///
/// Le subscription non passano da qui: `Link.split` le instrada sul
/// WebSocket, che riceve il token tramite `initialPayload`. Le chiamate di
/// auth pubbliche usano il client dedicato di `GraphQlBackendAuthApi`.
///
/// Fail-open: se `getAccessToken()` lancia, la request procede senza header
/// (coerente con la regola "no loading bloccante in sessione attiva").
class AuthAuthLink extends Link {
  AuthAuthLink({
    required AuthTokenService authService,
    UnauthorizedRecovery? recovery,
  }) : _authService = authService,
       _recovery = recovery;

  static const String _unauthenticatedCode = 'UNAUTHENTICATED';
  static const int _unauthorizedStatus = 401;

  final AuthTokenService _authService;
  final UnauthorizedRecovery? _recovery;

  @override
  Stream<Response> request(Request request, [NextLink? forward]) async* {
    final next = forward!;
    final token = await _currentToken();
    final recovery = _recovery;
    final canRetry =
        recovery != null &&
        token != null &&
        request.context.entry<AuthRetried>() == null;

    try {
      await for (final response in next(_withBearer(request, token))) {
        if (canRetry && _isUnauthenticated(response)) {
          yield* _retryOrYield(request, next, token, response);
          return;
        }
        yield response;
      }
    } on ServerException catch (error) {
      if (!canRetry || error.statusCode != _unauthorizedStatus) rethrow;
      final fresh = await recovery.recoverFromUnauthorized(
        rejectedToken: token,
      );
      if (fresh == null) rethrow;
      yield* _resend(request, next, fresh);
    }
  }

  Stream<Response> _retryOrYield(
    Request request,
    NextLink forward,
    String rejectedToken,
    Response original,
  ) async* {
    final fresh = await _recovery!.recoverFromUnauthorized(
      rejectedToken: rejectedToken,
    );
    if (fresh == null) {
      yield original;
      return;
    }
    yield* _resend(request, forward, fresh);
  }

  Stream<Response> _resend(Request request, NextLink forward, String token) =>
      forward(
        _withBearer(request.withContextEntry(const AuthRetried()), token),
      );

  Future<String?> _currentToken() async {
    try {
      return await _authService.getAccessToken();
    } catch (_) {
      return null; // fail-open
    }
  }

  Request _withBearer(Request request, String? token) {
    if (token == null || token.isEmpty) return request;
    return request.updateContextEntry<HttpLinkHeaders>(
      (prev) => HttpLinkHeaders(
        headers: {...?prev?.headers, 'Authorization': 'Bearer $token'},
      ),
    );
  }

  bool _isUnauthenticated(Response response) =>
      response.errors?.any(
        (error) => error.extensions?['code'] == _unauthenticatedCode,
      ) ??
      false;
}
