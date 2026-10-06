import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/auth/auth_session.dart';
import 'package:klimmeck_guide/repository/services/auth/auth.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/auth_fixtures.dart';
import '../../../helpers/auth_session_fixtures.dart';
import '../../../helpers/fakes/in_memory_session_store.dart';
import '../../../helpers/mocks.dart';

void main() {
  late MockBackendAuthApi api;
  late InMemorySessionStore store;
  late int teardowns;
  late List<AuthState> states;
  late int refreshCalls;

  setUp(() {
    api = MockBackendAuthApi();
    teardowns = 0;
    states = [];
    refreshCalls = 0;
  });

  SessionAuthTokenService buildService(FakeAsync async) {
    final service = SessionAuthTokenService(
      api: api,
      store: store,
      browser: MockBrowserAuthenticator(),
      backendBaseUrl: Uri.parse('http://backend.test/'),
      onSessionTeardown: () async => teardowns++,
      now: () => testNow.add(async.elapsed),
    );
    service.authStateStream.listen(states.add);
    return service;
  }

  void refreshAnswers(List<Object> outcomes) {
    final queue = [...outcomes];
    when(() => api.refreshSession(any())).thenAnswer((_) async {
      refreshCalls++;
      final outcome = queue.length > 1 ? queue.removeAt(0) : queue.first;
      if (outcome is AuthSession) return outcome;
      throw outcome;
    });
  }

  test('empty store resolves to signed out without touching the network', () {
    fakeAsync((async) {
      store = InMemorySessionStore();
      buildService(async).initialize();
      async.flushMicrotasks();

      expect(states, const [AuthBootstrapping(), AuthUnauthenticated()]);
      verifyNever(() => api.refreshSession(any()));
    });
  });

  test('stored session is refreshed and persisted before authenticating', () {
    fakeAsync((async) {
      store = InMemorySessionStore(refreshToken: 'r0');
      final session = buildAuthSession(refreshToken: 'r1');
      refreshAnswers([session]);
      String? storedAtAuthentication;
      final service = buildService(async);
      service.authStateStream.listen((state) {
        if (state is AuthAuthenticated) {
          storedAtAuthentication = store.refreshToken;
        }
      });

      service.initialize();
      async.flushMicrotasks();

      verify(() => api.refreshSession('r0')).called(1);
      expect(states, [
        const AuthBootstrapping(),
        AuthAuthenticated(
          user: buildTestUser(),
          accessToken: session.accessToken,
        ),
      ]);
      expect(store.refreshToken, 'r1');
      expect(storedAtAuthentication, 'r1');
      service.dispose();
    });
  });

  test('revoked session clears storage and reports an expired session', () {
    fakeAsync((async) {
      store = InMemorySessionStore(refreshToken: 'r0');
      refreshAnswers([const SessionRejected(sessionRevokedCode)]);

      buildService(async).initialize();
      async.flushMicrotasks();

      expect(states, const [
        AuthBootstrapping(),
        AuthUnauthenticated(reason: UnauthenticatedReason.sessionExpired),
      ]);
      expect(store.refreshToken, isNull);
      expect(teardowns, 1);
    });
  });

  test('UNAUTHENTICATED and BAD_REQUEST on refresh are not terminal', () {
    fakeAsync((async) {
      store = InMemorySessionStore(refreshToken: 'r0');
      refreshAnswers([
        const TransientAuthFailure(unauthenticatedCode),
        const TransientAuthFailure(badRequestCode),
      ]);
      final service = buildService(async);

      service.initialize();
      async.elapse(const Duration(seconds: 10));

      expect(refreshCalls, greaterThanOrEqualTo(3));
      expect(states, const [AuthBootstrapping()]);
      expect(store.refreshToken, 'r0');
      expect(teardowns, 0);
      service.dispose();
    });
  });

  test('transient failures retry after 1 s, 2 s and 4 s', () {
    fakeAsync((async) {
      store = InMemorySessionStore(refreshToken: 'r0');
      const failure = TransientAuthFailure('network');
      final session = buildAuthSession(refreshToken: 'r1');
      refreshAnswers([failure, failure, failure, session]);
      final service = buildService(async);

      service.initialize();
      async.flushMicrotasks();
      expect(refreshCalls, 1);

      for (final backoff in const [1, 2, 4]) {
        final callsBefore = refreshCalls;
        async.elapse(Duration(milliseconds: backoff * 1000 - 1));
        expect(refreshCalls, callsBefore, reason: 'too early for $backoff s');
        expect(states.last, const AuthBootstrapping());
        async.elapse(const Duration(milliseconds: 1));
        expect(refreshCalls, callsBefore + 1, reason: 'retry at $backoff s');
      }

      expect(states.last, isA<AuthAuthenticated>());
      expect(store.refreshToken, 'r1');
      service.dispose();
    });
  });

  test('keeps retrying indefinitely with a 30 s cap until disposed', () {
    fakeAsync((async) {
      store = InMemorySessionStore(refreshToken: 'r0');
      final attemptTimes = <Duration>[];
      when(() => api.refreshSession(any())).thenAnswer((_) async {
        attemptTimes.add(async.elapsed);
        throw const TransientAuthFailure('timeout');
      });
      final service = buildService(async);

      service.initialize();
      async.elapse(const Duration(minutes: 10));

      expect(attemptTimes.length, greaterThanOrEqualTo(20));
      for (var i = 1; i < attemptTimes.length; i++) {
        final gap = attemptTimes[i] - attemptTimes[i - 1];
        expect(gap, lessThanOrEqualTo(const Duration(seconds: 30)));
      }
      expect(states, const [AuthBootstrapping()]);

      service.dispose();
      final attemptsAtDispose = attemptTimes.length;
      async.elapse(const Duration(minutes: 5));
      expect(attemptTimes.length, attemptsAtDispose);
    });
  });

  test('initialize returns without waiting for the network', () {
    fakeAsync((async) {
      store = InMemorySessionStore(refreshToken: 'r0');
      final pendingRefresh = Completer<AuthSession>();
      when(
        () => api.refreshSession(any()),
      ).thenAnswer((_) => pendingRefresh.future);
      final service = buildService(async);
      var initialized = false;

      service.initialize().then((_) => initialized = true);
      async.flushMicrotasks();

      expect(initialized, isTrue);
      expect(states, const [AuthBootstrapping()]);
      verify(() => api.refreshSession('r0')).called(1);
      service.dispose();
    });
  });

  test('a late listener receives the current state immediately', () {
    fakeAsync((async) {
      store = InMemorySessionStore();
      final service = buildService(async);
      service.initialize();
      async.flushMicrotasks();

      final lateStates = <AuthState>[];
      service.authStateStream.listen(lateStates.add);
      async.flushMicrotasks();

      expect(lateStates, const [AuthUnauthenticated()]);
    });
  });
}
