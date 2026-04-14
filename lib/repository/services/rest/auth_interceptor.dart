import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:klimmeck_guide/repository/services/auth/auth_token_service.dart';

/// Dio interceptor che inietta il token OAuth nell'header `Authorization`.
///
/// Aggiunge `Authorization: Bearer <token>` a ogni request quando il token
/// è disponibile. Fail-open: in caso di errore nel fetch del token, la
/// request procede senza header (coerente con la regola "no loading bloccante").
///
/// Phase 11 estenderà questo interceptor con retry + refresh token (D-06
/// auth-session-bootstrap/11-CONTEXT.md). In Phase 1 il comportamento è
/// solo header injection.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({required AuthTokenService authService})
    : _authService = authService;

  final AuthTokenService _authService;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      final token = await _authService.getAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AuthInterceptor] token fetch failed: $e');
      }
    }
    handler.next(options);
  }
}
