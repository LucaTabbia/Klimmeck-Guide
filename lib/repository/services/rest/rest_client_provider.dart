import 'package:dio/dio.dart';
import 'package:klimmeck_guide/config/env_config.dart';
import 'package:klimmeck_guide/repository/services/auth/auth_token_service.dart';
import 'package:klimmeck_guide/repository/services/rest/auth_interceptor.dart';

/// Client HTTP basato su Dio con auth injection.
///
/// Il singleton statico è stato rimosso: ogni istanza è owned dalla
/// `KlimmeckRest` che la riceve tramite DI costruttore da `main.dart`.
/// Questo permette la sostituzione drop-in dell'`AuthTokenService` in
/// Phase 11 senza modificare il layer REST.
class RestClient {
  RestClient({required AuthTokenService authTokenService})
    : _dio = Dio(
        BaseOptions(
          baseUrl: EnvConfig.baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          headers: {'Content-Type': 'application/json'},
        ),
      ) {
    _dio.interceptors.add(AuthInterceptor(authService: authTokenService));
  }

  final Dio _dio;

  Dio get dio => _dio;
}
