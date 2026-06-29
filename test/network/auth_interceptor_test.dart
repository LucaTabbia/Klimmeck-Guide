import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/repository/services/auth/auth_token_service.dart';
import 'package:klimmeck_guide/repository/services/rest/auth_interceptor.dart';
import 'package:mocktail/mocktail.dart';

/// RED — Dio AuthInterceptor (DEV-AUTH-05).
/// Diventerà GREEN dopo Plan 03.
class MockAuthTokenService extends Mock implements AuthTokenService {}

void main() {
  late MockAuthTokenService mockService;
  late AuthInterceptor interceptor;

  setUp(() {
    mockService = MockAuthTokenService();
    interceptor = AuthInterceptor(authService: mockService);
  });

  group('AuthInterceptor', () {
    test(
      'aggiunge header Authorization: Bearer <token> quando getAccessToken() ritorna token',
      () async {
        when(() => mockService.getAccessToken())
            .thenAnswer((_) async => 'token-abc');

        final options = RequestOptions(path: '/test');
        final handler = RequestInterceptorHandler();

        await interceptor.onRequest(options, handler);

        expect(options.headers['Authorization'], equals('Bearer token-abc'));
      },
    );

    test(
      'NON aggiunge header Authorization quando getAccessToken() ritorna null',
      () async {
        when(() => mockService.getAccessToken()).thenAnswer((_) async => null);

        final options = RequestOptions(path: '/test');
        final handler = RequestInterceptorHandler();

        await interceptor.onRequest(options, handler);

        expect(options.headers.containsKey('Authorization'), isFalse);
      },
    );
  });
}
