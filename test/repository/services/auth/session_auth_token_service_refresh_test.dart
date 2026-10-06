import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/auth/auth_session.dart';
import 'package:klimmeck_guide/models/enums/role_type.dart';
import 'package:klimmeck_guide/models/user.dart';
import 'package:klimmeck_guide/repository/services/auth/auth.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/auth_fixtures.dart';
import '../../../helpers/auth_session_fixtures.dart';
import '../../../helpers/fakes/in_memory_session_store.dart';
import '../../../helpers/mocks.dart';

const Duration _proactiveDelay = Duration(minutes: 14);

AuthSession _sessionIssuedAt(
  Duration offset, {
  required String refreshToken,
  User? user,
}) => buildAuthSession(
  accessToken: buildTestJwt(issuedAt: testNow.add(offset)),
  expiresAt: testNow.add(offset + testAccessTokenLifetime),
  refreshToken: refreshToken,
  user: user,
);

void main() {
  late MockBackendAuthApi api;
  late InMemorySessionStore store;
  late int teardowns;
  late List<AuthState> states;
  late List<Duration> refreshTimes;
  late List<Object> refreshOutcomes;

  setUp(() {
    api = MockBackendAuthApi();
    store = InMemorySessionStore(refreshToken: 'r0');
    teardowns = 0;
    states = [];
    refreshTimes = [];
    refreshOutcomes = [];
  });

  /// Ogni chiamata consuma il primo esito; l'ultimo si ripete.
  void answerRefreshes(FakeAsync async, List<Object> outcomes) {
    refreshOutcomes = [...outcomes];
    when(() => api.refreshSession(any())).thenAnswer((_) async {
      refreshTimes.add(async.elapsed);
      final outcome = refreshOutcomes.length > 1
          ? refreshOutcomes.removeAt(0)
          : refreshOutcomes.first;
      if (outcome is AuthSession) return outcome;
      throw outcome;
    });
  }

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

  String? tokenNow(SessionAuthTokenService service, FakeAsync async) {
    String? token;
    service.getAccessToken().then((value) => token = value);
    async.flushMicrotasks();
    return token;
  }

  test('a valid token is served from memory without a network call', () {
    fakeAsync((async) {
      final session = _sessionIssuedAt(Duration.zero, refreshToken: 'r1');
      answerRefreshes(async, [session]);
      final service = startService(async);

      async.elapse(const Duration(minutes: 13));

      expect(tokenNow(service, async), session.accessToken);
      expect(refreshTimes, hasLength(1));
      service.dispose();
    });
  });

  test('concurrent callers past the refresh time share one refresh', () {
    fakeAsync((async) {
      var clock = testNow;
      final first = _sessionIssuedAt(Duration.zero, refreshToken: 'r1');
      final second = _sessionIssuedAt(_proactiveDelay, refreshToken: 'r2');
      when(() => api.refreshSession('r0')).thenAnswer((_) async => first);
      final pendingRefresh = Completer<AuthSession>();
      when(
        () => api.refreshSession('r1'),
      ).thenAnswer((_) => pendingRefresh.future);
      final service = startService(async, now: () => clock);

      clock = testNow.add(_proactiveDelay + const Duration(seconds: 1));
      final tokens = <String?>[];
      for (var i = 0; i < 5; i++) {
        service.getAccessToken().then(tokens.add);
      }
      async.flushMicrotasks();
      pendingRefresh.complete(second);
      async.flushMicrotasks();

      verify(() => api.refreshSession('r1')).called(1);
      expect(tokens, List.filled(5, second.accessToken));
      expect(store.refreshToken, 'r2');
      service.dispose();
    });
  });

  test('proactive refresh fires 60 s before a 15 min token expires', () {
    fakeAsync((async) {
      answerRefreshes(async, [
        _sessionIssuedAt(Duration.zero, refreshToken: 'r1'),
        _sessionIssuedAt(_proactiveDelay, refreshToken: 'r2'),
        _sessionIssuedAt(_proactiveDelay * 2, refreshToken: 'r3'),
      ]);
      final service = startService(async);

      async.elapse(_proactiveDelay - const Duration(seconds: 1));
      expect(refreshTimes, hasLength(1));
      async.elapse(const Duration(seconds: 1));
      expect(refreshTimes, [Duration.zero, _proactiveDelay]);

      async.elapse(_proactiveDelay);
      expect(refreshTimes, [
        Duration.zero,
        _proactiveDelay,
        _proactiveDelay * 2,
      ]);
      expect(store.refreshToken, 'r3');
      service.dispose();
    });
  });

  test('an undecodable, already expired token refreshes on the 30 s floor', () {
    fakeAsync((async) {
      answerRefreshes(async, [
        buildAuthSession(
          accessToken: 'opaque-token',
          expiresAt: testNow.subtract(const Duration(minutes: 1)),
          refreshToken: 'r1',
        ),
      ]);
      final service = startService(async);

      async.elapse(const Duration(seconds: 29));
      expect(refreshTimes, hasLength(1));
      async.elapse(const Duration(seconds: 1));
      expect(refreshTimes, hasLength(2));

      async.elapse(const Duration(seconds: 90));
      expect(refreshTimes.length - 1, lessThanOrEqualTo(4));
      service.dispose();
    });
  });

  test('a transient proactive failure retries with backoff capped at 60 s', () {
    fakeAsync((async) {
      final session = _sessionIssuedAt(Duration.zero, refreshToken: 'r1');
      answerRefreshes(async, [session, const TransientAuthFailure('network')]);
      final service = startService(async);

      async.elapse(_proactiveDelay);
      expect(refreshTimes.last, _proactiveDelay);
      async.elapse(const Duration(seconds: 1));
      expect(refreshTimes.last, _proactiveDelay + const Duration(seconds: 1));
      async.elapse(const Duration(seconds: 2));
      expect(refreshTimes.last, _proactiveDelay + const Duration(seconds: 3));

      async.elapse(const Duration(minutes: 10));
      final gaps = [
        for (var i = 2; i < refreshTimes.length; i++)
          refreshTimes[i] - refreshTimes[i - 1],
      ];
      expect(gaps.last, const Duration(seconds: 60));
      expect(
        gaps,
        everyElement(lessThanOrEqualTo(const Duration(seconds: 60))),
      );
      expect(states.whereType<AuthUnauthenticated>(), isEmpty);
      expect(store.refreshToken, 'r1');
      expect(tokenNow(service, async), session.accessToken);
      service.dispose();
    });
  });

  test('a rejected session ends with teardown, empty storage and notice', () {
    fakeAsync((async) {
      answerRefreshes(async, [
        _sessionIssuedAt(Duration.zero, refreshToken: 'r1'),
        const SessionRejected(sessionExpiredCode),
      ]);
      final service = startService(async);

      async.elapse(_proactiveDelay);

      expect(teardowns, 1);
      expect(store.refreshToken, isNull);
      expect(
        states.last,
        const AuthUnauthenticated(reason: UnauthenticatedReason.sessionExpired),
      );
      expect(tokenNow(service, async), isNull);
      async.elapse(const Duration(minutes: 30));
      expect(refreshTimes, hasLength(2));
      service.dispose();
    });
  });

  test('UNAUTHENTICATED on an in-session refresh never logs out', () {
    fakeAsync((async) {
      answerRefreshes(async, [
        _sessionIssuedAt(Duration.zero, refreshToken: 'r1'),
        const TransientAuthFailure(unauthenticatedCode),
      ]);
      final service = startService(async);

      async.elapse(_proactiveDelay + const Duration(seconds: 1));

      expect(refreshTimes, hasLength(3));
      expect(teardowns, 0);
      expect(store.refreshToken, 'r1');
      expect(states.last, isA<AuthAuthenticated>());
      service.dispose();
    });
  });

  test('a failed storage write keeps the rotated session in memory', () {
    fakeAsync((async) {
      final rotated = _sessionIssuedAt(_proactiveDelay, refreshToken: 'r2');
      answerRefreshes(async, [
        _sessionIssuedAt(Duration.zero, refreshToken: 'r1'),
        rotated,
        _sessionIssuedAt(_proactiveDelay * 2, refreshToken: 'r3'),
      ]);
      final service = startService(async);
      store.failNextWrite = true;

      async.elapse(_proactiveDelay);

      expect(store.refreshToken, 'r1');
      expect(tokenNow(service, async), rotated.accessToken);
      expect(states.whereType<AuthUnauthenticated>(), isEmpty);

      async.elapse(_proactiveDelay);
      verify(() => api.refreshSession('r2')).called(1);
      expect(store.refreshToken, 'r3');
      service.dispose();
    });
  });

  test('rotation with the same user does not re-emit the state', () {
    fakeAsync((async) {
      answerRefreshes(async, [
        _sessionIssuedAt(Duration.zero, refreshToken: 'r1'),
        _sessionIssuedAt(_proactiveDelay, refreshToken: 'r2'),
      ]);
      final service = startService(async);

      async.elapse(_proactiveDelay);

      expect(refreshTimes, hasLength(2));
      expect(states, [const AuthBootstrapping(), isA<AuthAuthenticated>()]);
      service.dispose();
    });
  });

  test('rotation that changes the user id re-emits the new identity', () {
    fakeAsync((async) {
      final promoted = User(
        id: 'other-user-id',
        twitchId: testTwitchId,
        twitchPoints: 0,
        currentCharacter: null,
        role: RoleType.guard,
      );
      final rotated = _sessionIssuedAt(
        _proactiveDelay,
        refreshToken: 'r2',
        user: promoted,
      );
      answerRefreshes(async, [
        _sessionIssuedAt(Duration.zero, refreshToken: 'r1'),
        rotated,
      ]);
      final service = startService(async);

      async.elapse(_proactiveDelay);

      expect(
        states.last,
        AuthAuthenticated(user: promoted, accessToken: rotated.accessToken),
      );
      service.dispose();
    });
  });
}
