import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:klimmeck_guide/repository/services/auth/auth_token_service.dart';
import 'package:klimmeck_guide/repository/services/auth/unauthorized_recovery.dart';

/// Dio interceptor che inietta il token OAuth nell'header `Authorization`
/// e ritenta UNA volta una richiesta rifiutata con 401.
///
/// Aggiunge `Authorization: Bearer <token>` a ogni request quando il token
/// è disponibile. Fail-open: in caso di errore nel fetch del token, la
/// request procede senza header (coerente con la regola "no loading bloccante").
///
/// Su un 401, se sono presenti [UnauthorizedRecovery] e [Dio], la richiesta
/// viene rifatta una sola volta (anche con `FormData`, clonato) dopo il
/// refresh. Se la recovery non produce un token, o il retry è già avvenuto,
/// il chiamante riceve l'errore originale.
///
/// Resta un `Interceptor` semplice (non `QueuedInterceptor`): il single-flight
/// è nel servizio, e una coda andrebbe in deadlock rifacendo la richiesta
/// sullo stesso `Dio`.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required AuthTokenService authService,
    UnauthorizedRecovery? recovery,
    Dio? dio,
  }) : _authService = authService,
       _recovery = recovery,
       _dio = dio;

  static const String _retriedKey = 'klimmeck.authRetried';
  static const int _unauthorizedStatus = 401;
  static const String _bearerPrefix = 'Bearer ';

  final AuthTokenService _authService;
  final UnauthorizedRecovery? _recovery;
  final Dio? _dio;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      final token = await _authService.getAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = '$_bearerPrefix$token';
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AuthInterceptor] token fetch failed: ${e.runtimeType}');
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    final recovery = _recovery;
    final dio = _dio;
    final rejectedToken = _bearerOf(options);
    if (err.response?.statusCode != _unauthorizedStatus ||
        recovery == null ||
        dio == null ||
        rejectedToken == null ||
        options.extra[_retriedKey] == true) {
      return handler.next(err);
    }

    final fresh = await recovery.recoverFromUnauthorized(
      rejectedToken: rejectedToken,
    );
    if (fresh == null) return handler.next(err);

    final data = options.data;
    final retry = options.copyWith(
      extra: {...options.extra, _retriedKey: true},
      data: data is FormData ? data.clone() : data,
    );
    try {
      // onRequest riscrive Authorization col token fresco.
      handler.resolve(await dio.fetch<dynamic>(retry));
    } on DioException catch (error) {
      handler.reject(error);
    }
  }

  String? _bearerOf(RequestOptions options) {
    final header = options.headers['Authorization'];
    if (header is! String || !header.startsWith(_bearerPrefix)) return null;
    return header.substring(_bearerPrefix.length);
  }
}
