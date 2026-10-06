import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/auth/auth_session.dart';
import 'package:klimmeck_guide/models/auth/login_challenge.dart';
import 'package:klimmeck_guide/models/enums/role_type.dart';
import 'package:klimmeck_guide/models/user.dart';
import 'package:klimmeck_guide/repository/services/auth/auth.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/auth_fixtures.dart';
import '../../../helpers/auth_session_fixtures.dart';
import '../../../helpers/fakes/in_memory_session_store.dart';
import '../../../helpers/mocks.dart';

const Duration _logoutTimeout = Duration(seconds: 4);
const Duration _proactiveDelay = Duration(minutes: 14);
const AuthUnauthenticated _signedOut = AuthUnauthenticated();

const LoginChallenge _challenge = LoginChallenge(
  codeVerifier: 'verifier-test',
  codeChallenge: 'challenge-test',
);

final User _userB = User(
  id: 'user-b-id',
  twitchId: 'twitch-b-id',
  twitchPoints: 0,
  currentCharacter: null,
  role: RoleType.adventurer,
);

final AuthSession _sessionA = buildAuthSession(refreshToken: 'r1');

final AuthSession _rotatedSessionA = buildAuthSession(
  accessToken: buildTestJwt(issuedAt: testNow.add(_proactiveDelay)),
  expiresAt: testNow.add(_proactiveDelay + testAccessTokenLifetime),
  refreshToken: 'r2',
);

final AuthSession _sessionB = buildAuthSession(
  accessToken: buildTestJwt(subject: 'user-b-id'),
  refreshToken: 'login-refresh-b',
  user: _userB,
);

void main() {
  late MockBackendAuthApi api;
  late MockBrowserAuthenticator browser;
  late MockSessionTeardownHook teardown;
  late InMemorySessionStore store;
  late List<AuthState> states;

  setUpAll(() => registerFallbackValue(Uri()));

  setUp(() {
    api = MockBackendAuthApi();
    browser = MockBrowserAuthenticator();
    teardown = MockSessionTeardownHook();
    store = InMemorySessionStore(refreshToken: 'r0');
    states = [];
    when(() => api.refreshSession('r0')).thenAnswer((_) async => _sessionA);
    when(() => api.logout(any())).thenAnswer((_) async {});
    when(() => teardown()).thenAnswer((_) async {});
  });

  SessionAuthTokenService startService(
    FakeAsync async, {
    DateTime Function()? now,
  }) {
    final service = SessionAuthTokenService(
      api: api,
      store: store,
      browser: browser,
      backendBaseUrl: Uri.parse('http://backend.test/'),
      onSessionTeardown: teardown.call,
      now: now ?? () => testNow.add(async.elapsed),
      createChallenge: () => _challenge,
      logoutTimeout: _logoutTimeout,
    );
    service.authStateStream.listen(states.add);
    service.initialize();
    async.flushMicrotasks();
    return service;
  }

  /// Avvia `logout()` e ritorna una funzione che dice se è terminato;
  /// un errore di `logout()` fa fallire il test.
  bool Function() startLogout(SessionAuthTokenService service) {
    var done = false;
    service.logout().then<void>((_) => done = true);
    return () => done;
  }

  void logoutNow(SessionAuthTokenService service, FakeAsync async) {
    final isDone = startLogout(service);
    async.flushMicrotasks();
    expect(isDone(), isTrue, reason: 'logout() did not complete');
  }

  String? tokenNow(SessionAuthTokenService service, FakeAsync async) {
    String? token;
    service.getAccessToken().then((value) => token = value);
    async.flushMicrotasks();
    return token;
  }

  void expectSignedOut(SessionAuthTokenService service, FakeAsync async) {
    verify(() => teardown()).called(1);
    expect(store.refreshToken, isNull);
    expect(states.last, _signedOut);
    expect(tokenNow(service, async), isNull);
  }

  group('logout with an active session', () {
    test('invalidates the backend session before the local teardown', () {
      fakeAsync((async) {
        final service = startService(async);

        logoutNow(service, async);

        verifyInOrder([
          () => api.logout(_sessionA.accessToken),
          () => teardown(),
        ]);
        expect(store.refreshToken, isNull);
        expect(states.last, _signedOut);
        expect(tokenNow(service, async), isNull);
        service.dispose();
      });
    });

    test('emits signedOut only after teardown and storage clear', () {
      fakeAsync((async) {
        final events = <String>[];
        when(() => api.logout(any())).thenAnswer((_) async {
          events.add('backend');
        });
        when(() => teardown()).thenAnswer((_) async {
          events.add('teardown');
        });
        final service = startService(async);
        service.authStateStream.listen((state) {
          if (state is! AuthUnauthenticated) return;
          events.add('emit, storage=${store.refreshToken}');
        });
        async.flushMicrotasks();

        logoutNow(service, async);

        expect(events, ['backend', 'teardown', 'emit, storage=null']);
        service.dispose();
      });
    });

    test('completes offline when the backend call fails', () {
      fakeAsync((async) {
        when(
          () => api.logout(any()),
        ).thenAnswer((_) async => throw const TransientAuthFailure('network'));
        final service = startService(async);

        logoutNow(service, async);

        expectSignedOut(service, async);
        service.dispose();
      });
    });

    test('a backend that never answers delays the teardown by at most '
        'the timeout', () {
      fakeAsync((async) {
        when(
          () => api.logout(any()),
        ).thenAnswer((_) => Completer<void>().future);
        final service = startService(async);

        final isDone = startLogout(service);
        async.elapse(_logoutTimeout - const Duration(milliseconds: 1));
        expect(isDone(), isFalse);
        verifyNever(() => teardown());

        async.elapse(const Duration(milliseconds: 1));

        expect(isDone(), isTrue);
        expectSignedOut(service, async);
        service.dispose();
      });
    });
  });

  group('logout with an expired access token', () {
    test('refreshes first and invalidates the backend with the new token', () {
      fakeAsync((async) {
        var clock = testNow;
        when(
          () => api.refreshSession('r1'),
        ).thenAnswer((_) async => _rotatedSessionA);
        final service = startService(async, now: () => clock);
        clock = testNow.add(_proactiveDelay + const Duration(seconds: 1));

        logoutNow(service, async);

        verify(() => api.refreshSession('r1')).called(1);
        verify(() => api.logout(_rotatedSessionA.accessToken)).called(1);
        expectSignedOut(service, async);
        service.dispose();
      });
    });

    test('a transient refresh failure still completes the teardown', () {
      fakeAsync((async) {
        var clock = testNow;
        when(
          () => api.refreshSession('r1'),
        ).thenAnswer((_) async => throw const TransientAuthFailure('network'));
        final service = startService(async, now: () => clock);
        clock = testNow.add(_proactiveDelay + const Duration(seconds: 1));

        logoutNow(service, async);

        verify(() => api.logout(_sessionA.accessToken)).called(1);
        expectSignedOut(service, async);
        service.dispose();
      });
    });
  });

  test('without a session skips the backend and still signs out', () {
    fakeAsync((async) {
      store = InMemorySessionStore();
      final service = startService(async);

      logoutNow(service, async);

      verifyNever(() => api.logout(any()));
      expect(states.last, _signedOut);
      expect(tokenNow(service, async), isNull);
      service.dispose();
    });
  });

  group('epoch guard', () {
    test('a cold-start refresh completing after logout is discarded', () {
      fakeAsync((async) {
        final pendingRefresh = Completer<AuthSession>();
        when(
          () => api.refreshSession('r0'),
        ).thenAnswer((_) => pendingRefresh.future);
        final service = startService(async);

        final isDone = startLogout(service);
        async.elapse(_logoutTimeout);
        expect(isDone(), isTrue);
        final writesAtLogout = store.writes;

        pendingRefresh.complete(_sessionA);
        async.flushMicrotasks();
        async.elapse(const Duration(hours: 1));

        verifyNever(() => api.logout(any()));
        expect(store.refreshToken, isNull);
        expect(store.writes, writesAtLogout);
        expect(states.whereType<AuthAuthenticated>(), isEmpty);
        expect(states.last, _signedOut);
        expect(tokenNow(service, async), isNull);
        service.dispose();
      });
    });

    test('a reactive refresh completing after logout is discarded', () {
      fakeAsync((async) {
        final pendingRefresh = Completer<AuthSession>();
        when(
          () => api.refreshSession('r1'),
        ).thenAnswer((_) => pendingRefresh.future);
        final service = startService(async);
        String? recovered = 'not-settled';
        service
            .recoverFromUnauthorized(rejectedToken: _sessionA.accessToken)
            .then((token) => recovered = token);
        async.flushMicrotasks();

        logoutNow(service, async);
        final statesAtLogout = [...states];

        pendingRefresh.complete(_rotatedSessionA);
        async.flushMicrotasks();
        async.elapse(const Duration(hours: 1));

        expect(recovered, isNull);
        expect(store.refreshToken, isNull);
        expect(states, statesAtLogout);
        expect(states.last, _signedOut);
        expect(tokenNow(service, async), isNull);
        verify(() => api.refreshSession('r1')).called(1);
        service.dispose();
      });
    });
  });

  test('account switch: logout then login leaves only user B', () {
    fakeAsync((async) {
      when(
        () => browser.authenticate(
          startUrl: any(named: 'startUrl'),
          callbackScheme: any(named: 'callbackScheme'),
        ),
      ).thenAnswer((_) async => 'klimmeck://auth?ticket=T');
      when(
        () => api.exchangeLoginTicket(
          ticket: any(named: 'ticket'),
          codeVerifier: any(named: 'codeVerifier'),
        ),
      ).thenAnswer((_) async => _sessionB);
      final service = startService(async);

      logoutNow(service, async);
      service.login();
      async.flushMicrotasks();

      expect(states, [
        const AuthBootstrapping(),
        AuthAuthenticated(
          user: buildTestUser(),
          accessToken: _sessionA.accessToken,
        ),
        _signedOut,
        AuthAuthenticated(user: _userB, accessToken: _sessionB.accessToken),
      ]);
      expect(tokenNow(service, async), _sessionB.accessToken);
      expect(store.refreshToken, 'login-refresh-b');
      service.dispose();
    });
  });

  group('dispose', () {
    test('cancels the timers: no refresh runs afterwards', () {
      fakeAsync((async) {
        final service = startService(async);

        service.dispose();
        async.elapse(const Duration(hours: 1));

        verify(() => api.refreshSession(any())).called(1);
      });
    });

    test('closes the state stream', () async {
      store = InMemorySessionStore();
      final service = SessionAuthTokenService(
        api: api,
        store: store,
        browser: browser,
        backendBaseUrl: Uri.parse('http://backend.test/'),
        onSessionTeardown: teardown.call,
      );
      await service.initialize();
      final closed = expectLater(
        service.authStateStream,
        emitsInOrder([_signedOut, emitsDone]),
      );

      service.dispose();

      await closed;
    });
  });
}
