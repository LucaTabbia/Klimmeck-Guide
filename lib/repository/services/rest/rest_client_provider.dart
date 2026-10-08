import 'package:dio/dio.dart';
import 'package:klimmeck_guide/config/env_config.dart';
import 'package:klimmeck_guide/repository/services/auth/auth_token_service.dart';
import 'package:klimmeck_guide/repository/services/auth/unauthorized_recovery.dart';
import 'package:klimmeck_guide/repository/services/rest/auth_interceptor.dart';

/// Client HTTP basato su Dio con auth injection.
///
/// Il singleton statico è stato rimosso: ogni istanza è owned dalla
/// `KlimmeckRest` che la riceve tramite DI costruttore da `main.dart`.
/// L'`AuthInterceptor` riceve il `Dio` del client e l'eventuale
/// [UnauthorizedRecovery] per il retry-once dopo un 401.
class RestClient {
  RestClient({
    required AuthTokenService authTokenService,
    UnauthorizedRecovery? recovery,
  }) : _dio = Dio(
         BaseOptions(
           baseUrl: EnvConfig.baseUrl,
           connectTimeout: const Duration(seconds: 10),
           receiveTimeout: const Duration(seconds: 10),
           headers: {'Content-Type': 'application/json'},
         ),
       ) {
    _dio.interceptors.add(
      AuthInterceptor(
        authService: authTokenService,
        recovery: recovery,
        dio: _dio,
      ),
    );
  }

  final Dio _dio;

  Dio get dio => _dio;
}
