import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/auth/auth_session.dart';
import 'package:klimmeck_guide/repository/services/auth/auth.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/auth_session_fixtures.dart';
import '../../../helpers/fakes/in_memory_session_store.dart';
import '../../../helpers/mocks.dart';

const Duration _proactiveDelay = Duration(minutes: 14);

final AuthSession _firstSession = buildAuthSession(
  accessToken: buildTestJwt(),
  refreshToken: 'r1',
);

final AuthSession _rotatedSession = buildAuthSession(
  accessToken: buildTestJwt(issuedAt: testNow.add(_proactiveDelay)),
  expiresAt: testNow.add(_proactiveDelay + testAccessTokenLifetime),
  refreshToken: 'r2',
);

void main() {
  late MockBackendAuthApi api;
  late InMemorySessionStore store;
  late int teardowns;
  late List<AuthState> states;

  setUp(() {
    api = MockBackendAuthApi();
    store = InMemorySessionStore(refreshToken: 'r0');
    teardowns = 0;
    states = [];
    when(() => api.refreshSession('r0')).thenAnswer((_) async => _firstSession);
  });

  SessionAuthTokenService startService(
    FakeAsync async, {
    DateTime Function()? now,
  }) {
    final service = SessionAuthTokenService(
      api: api,
      store: store,
      browser: MockBrowserAuthenticator(),
      backendBaseUrl: Uri.parse('http://backend.test/'),
      onSessionTeardown: () async => teardowns++,
      now: now ?? () => testNow.add(async.elapsed),
    );
    service.authStateStream.listen(states.add);
    service.initialize();
    async.flushMicrotasks();
    return service;
  }

  T? resolve<T>(Future<T> future, FakeAsync async) {
    T? value;
    future.then((result) => value = result);
    async.flushMicrotasks();
    return value;
  }

  group('recoverFromUnauthorized', () {
    test('returns the current token without a refresh when it already '
        'rotated', () {
      fakeAsync((async) {
        when(
          () => api.refreshSession('r1'),
        ).thenAnswer((_) async => _rotatedSession);
        final service = startService(async);
        resolve(
          service.recoverFromUnauthorized(
            rejectedToken: _firstSession.accessToken,
          ),
          async,
        );

        final token = resolve(
          service.recoverFromUnauthorized(
            rejectedToken: _firstSession.accessToken,
          ),
          async,
        );

        expect(token, _rotatedSession.accessToken);
        verify(() => api.refreshSession('r1')).called(1);
        service.dispose();
      });
    });

    test('returns null for a token never issued to this session', () {
      fakeAsync((async) {
        final service = startService(async);

        final token = resolve(
          service.recoverFromUnauthorized(rejectedToken: 'foreign-access'),
          async,
        );

        expect(token, isNull);
        verify(() => api.refreshSession(any())).called(1);
        service.dispose();
      });
    });

    test('forces one refresh when the rejected token is the current one', () {
      fakeAsync((async) {
        when(
          () => api.refreshSession('r1'),
        ).thenAnswer((_) async => _rotatedSession);
        final service = startService(async);

        final token = resolve(
          service.recoverFromUnauthorized(
            rejectedToken: _firstSession.accessToken,
          ),
          async,
        );

        expect(token, _rotatedSession.accessToken);
        verify(() => api.refreshSession('r1')).called(1);
        expect(store.refreshToken, 'r2');
        service.dispose();
      });
    });

    test('concurrent recoveries and token reads share a single refresh', () {
      fakeAsync((async) {
        var clock = testNow;
        final pendingRefresh = Completer<AuthSession>();
        when(
          () => api.refreshSession('r1'),
        ).thenAnswer((_) => pendingRefresh.future);
        final service = startService(async, now: () => clock);

        clock = testNow.add(_proactiveDelay + const Duration(seconds: 1));
        final tokens = <String?>[];
        for (var i = 0; i < 3; i++) {
          service
              .recoverFromUnauthorized(rejectedToken: _firstSession.accessToken)
              .then(tokens.add);
        }
        for (var i = 0; i < 2; i++) {
          service.getAccessToken().then(tokens.add);
        }
        async.flushMicrotasks();
        pendingRefresh.complete(_rotatedSession);
        async.flushMicrotasks();

        verify(() => api.refreshSession('r1')).called(1);
        expect(tokens, List.filled(5, _rotatedSession.accessToken));
        service.dispose();
      });
    });

    test('a rejected session returns null and ends the session as '
        'expired', () {
      fakeAsync((async) {
        when(() => api.refreshSession('r1')).thenAnswer(
          (_) async => throw const SessionRejected('SESSION_REVOKED'),
        );
        final service = startService(async);

        final token = resolve(
          service.recoverFromUnauthorized(
            rejectedToken: _firstSession.accessToken,
          ),
          async,
        );

        expect(token, isNull);
        expect(teardowns, 1);
        expect(store.refreshToken, isNull);
        expect(
          states.last,
          const AuthUnauthenticated(
            reason: UnauthenticatedReason.sessionExpired,
          ),
        );
        service.dispose();
      });
    });

    test('a transient failure returns null and keeps the session', () {
      fakeAsync((async) {
        when(
          () => api.refreshSession('r1'),
        ).thenAnswer((_) async => throw const TransientAuthFailure('network'));
        final service = startService(async);
        final statesBefore = [...states];

        final token = resolve(
          service.recoverFromUnauthorized(
            rejectedToken: _firstSession.accessToken,
          ),
          async,
        );

        expect(token, isNull);
        expect(states, statesBefore);
        expect(states.last, isA<AuthAuthenticated>());
        expect(store.refreshToken, 'r1');
        expect(teardowns, 0);
        expect(resolve(service.getAccessToken(), async), isNotNull);
        service.dispose();
      });
    });

    test('without a session returns null and calls nothing', () {
      fakeAsync((async) {
        store = InMemorySessionStore();
        final service = startService(async);

        final token = resolve(
          service.recoverFromUnauthorized(rejectedToken: 'any-token'),
          async,
        );

        expect(token, isNull);
        verifyNever(() => api.refreshSession(any()));
        service.dispose();
      });
    });
  });

  group('handleRevocation', () {
    test('tears the session down locally without calling the backend', () {
      fakeAsync((async) {
        when(
          () => api.refreshSession('r1'),
        ).thenAnswer((_) async => _rotatedSession);
        final service = startService(async);

        service.handleRevocation();
        async.flushMicrotasks();

        verifyNever(() => api.logout(any()));
        expect(teardowns, 1);
        expect(store.refreshToken, isNull);
        expect(
          states.last,
          const AuthUnauthenticated(
            reason: UnauthenticatedReason.sessionExpired,
          ),
        );
        expect(resolve(service.getAccessToken(), async), isNull);
        service.dispose();
      });
    });

    test('no proactive refresh fires after a revocation', () {
      fakeAsync((async) {
        when(
          () => api.refreshSession('r1'),
        ).thenAnswer((_) async => _rotatedSession);
        final service = startService(async);

        service.handleRevocation();
        async.flushMicrotasks();
        async.elapse(const Duration(hours: 1));

        verifyNever(() => api.refreshSession('r1'));
        expect(store.refreshToken, isNull);
        service.dispose();
      });
    });
  });
}
