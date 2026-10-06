import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:klimmeck_guide/repository/services/rest/auth_interceptor.dart';

import '../helpers/fakes/fake_http_client_adapter.dart';
import '../helpers/mocks.dart';

void main() {
  late MockAuthTokenService mockService;
  late MockUnauthorizedRecovery mockRecovery;

  setUp(() {
    mockService = MockAuthTokenService();
    mockRecovery = MockUnauthorizedRecovery();
  });

  group('AuthInterceptor onRequest', () {
    late AuthInterceptor interceptor;

    setUp(() {
      interceptor = AuthInterceptor(authService: mockService);
    });

    test(
      'adds Authorization: Bearer <token> when a token is available',
      () async {
        when(
          () => mockService.getAccessToken(),
        ).thenAnswer((_) async => 'token-abc');
        final options = RequestOptions(path: '/test');

        await interceptor.onRequest(options, RequestInterceptorHandler());

        expect(options.headers['Authorization'], equals('Bearer token-abc'));
      },
    );

    test('omits Authorization when getAccessToken() returns null', () async {
      when(() => mockService.getAccessToken()).thenAnswer((_) async => null);
      final options = RequestOptions(path: '/test');

      await interceptor.onRequest(options, RequestInterceptorHandler());

      expect(options.headers.containsKey('Authorization'), isFalse);
    });
  });

  group('AuthInterceptor onError (retry-once)', () {
    Dio buildDio(FakeHttpClientAdapter adapter, {bool withRecovery = true}) {
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
      dio.httpClientAdapter = adapter;
      dio.interceptors.add(
        AuthInterceptor(
          authService: mockService,
          recovery: withRecovery ? mockRecovery : null,
          dio: dio,
        ),
      );
      return dio;
    }

    setUp(() {
      when(() => mockService.getAccessToken()).thenAnswer((_) async => 'A1');
    });

    test('retries once with the new token after a 401', () async {
      when(
        () => mockRecovery.recoverFromUnauthorized(rejectedToken: 'A1'),
      ).thenAnswer((_) async {
        when(() => mockService.getAccessToken()).thenAnswer((_) async => 'A2');
        return 'A2';
      });
      final adapter = FakeHttpClientAdapter([401, 200]);

      final response = await buildDio(adapter).get<dynamic>('/x');

      expect(response.statusCode, 200);
      expect(adapter.requests, hasLength(2));
      expect(adapter.requests[0].headers['Authorization'], 'Bearer A1');
      expect(adapter.requests[1].headers['Authorization'], 'Bearer A2');
    });

    test('does not retry a second time when the retry gets 401 too', () async {
      when(
        () => mockRecovery.recoverFromUnauthorized(rejectedToken: 'A1'),
      ).thenAnswer((_) async => 'A2');
      final adapter = FakeHttpClientAdapter([401, 401, 200]);

      await expectLater(
        buildDio(adapter).get<dynamic>('/x'),
        throwsA(
          isA<DioException>().having(
            (e) => e.response?.statusCode,
            'status',
            401,
          ),
        ),
      );
      expect(adapter.requests, hasLength(2));
      verify(
        () => mockRecovery.recoverFromUnauthorized(
          rejectedToken: any(named: 'rejectedToken'),
        ),
      ).called(1);
    });

    test('surfaces the original 401 when recovery yields null', () async {
      when(
        () => mockRecovery.recoverFromUnauthorized(rejectedToken: 'A1'),
      ).thenAnswer((_) async => null);
      final adapter = FakeHttpClientAdapter([401, 200]);

      await expectLater(
        buildDio(adapter).get<dynamic>('/x'),
        throwsA(isA<DioException>()),
      );
      expect(adapter.requests, hasLength(1));
    });

    test('does not retry when built without recovery', () async {
      final adapter = FakeHttpClientAdapter([401, 200]);

      await expectLater(
        buildDio(adapter, withRecovery: false).get<dynamic>('/x'),
        throwsA(isA<DioException>()),
      );
      expect(adapter.requests, hasLength(1));
    });

    test('does not call recovery for a non-401 error', () async {
      final adapter = FakeHttpClientAdapter([500]);

      await expectLater(
        buildDio(adapter).get<dynamic>('/x'),
        throwsA(isA<DioException>()),
      );
      verifyNever(
        () => mockRecovery.recoverFromUnauthorized(
          rejectedToken: any(named: 'rejectedToken'),
        ),
      );
    });

    test('retries a FormData request with a cloned body', () async {
      when(
        () => mockRecovery.recoverFromUnauthorized(rejectedToken: 'A1'),
      ).thenAnswer((_) async => 'A2');
      final adapter = FakeHttpClientAdapter([401, 200]);
      final form = FormData.fromMap({'field': 'value'});

      final response = await buildDio(
        adapter,
      ).post<dynamic>('/upload', data: form);

      expect(response.statusCode, 200);
      expect(adapter.requests, hasLength(2));
    });
  });
}
