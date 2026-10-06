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

const String _ticketCallback = 'klimmeck://auth?ticket=T';
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

final AuthSession _loginSession = buildAuthSession(
  accessToken: buildTestJwt(subject: 'user-b-id'),
  refreshToken: 'login-refresh',
  user: _userB,
);

void main() {
  late MockBackendAuthApi api;
  late MockBrowserAuthenticator browser;
  late InMemorySessionStore store;
  late List<AuthState> states;
  late int refreshCalls;

  setUpAll(() => registerFallbackValue(Uri()));

  setUp(() {
    api = MockBackendAuthApi();
    browser = MockBrowserAuthenticator();
    store = InMemorySessionStore();
    states = [];
    refreshCalls = 0;
  });

  void browserReturns(String callbackUrl) {
    when(
      () => browser.authenticate(
        startUrl: any(named: 'startUrl'),
        callbackScheme: any(named: 'callbackScheme'),
      ),
    ).thenAnswer((_) async => callbackUrl);
  }

  void browserThrows(Object error) {
    when(
      () => browser.authenticate(
        startUrl: any(named: 'startUrl'),
        callbackScheme: any(named: 'callbackScheme'),
      ),
    ).thenAnswer((_) async => throw error);
  }

  void exchangeAnswers(Future<AuthSession> Function() answer) {
    when(
      () => api.exchangeLoginTicket(
        ticket: any(named: 'ticket'),
        codeVerifier: any(named: 'codeVerifier'),
      ),
    ).thenAnswer((_) => answer());
  }

  /// Ogni chiamata consuma il primo esito; l'ultimo si ripete.
  void refreshAnswers(List<Object> outcomes) {
    final queue = [...outcomes];
    when(() => api.refreshSession(any())).thenAnswer((_) async {
      refreshCalls++;
      final outcome = queue.length > 1 ? queue.removeAt(0) : queue.first;
      if (outcome is AuthSession) return outcome;
      throw outcome;
    });
  }

  SessionAuthTokenService buildService(FakeAsync async) {
    final service = SessionAuthTokenService(
      api: api,
      store: store,
      browser: browser,
      backendBaseUrl: Uri.parse('http://backend.test/'),
      onSessionTeardown: () async {},
      now: () => testNow.add(async.elapsed),
      createChallenge: () => _challenge,
    );
    service.authStateStream.listen(states.add);
    return service;
  }

  void initialize(SessionAuthTokenService service, FakeAsync async) {
    service.initialize();
    async.flushMicrotasks();
  }

  /// Esegue `login()` e ritorna l'errore lanciato, o `null` se è riuscito.
  Object? runLogin(SessionAuthTokenService service, FakeAsync async) {
    Object? error;
    var settled = false;
    service.login().then(
      (_) => settled = true,
      onError: (Object e) {
        error = e;
        settled = true;
      },
    );
    async.flushMicrotasks();
    expect(settled, isTrue, reason: 'login() did not settle');
    return error;
  }

  String? tokenNow(SessionAuthTokenService service, FakeAsync async) {
    String? token;
    service.getAccessToken().then((value) => token = value);
    async.flushMicrotasks();
    return token;
  }

  group('successful login', () {
    test('opens the backend start url with the S256 challenge', () {
      fakeAsync((async) {
        browserReturns(_ticketCallback);
        exchangeAnswers(() async => _loginSession);
        final service = buildService(async);

        expect(runLogin(service, async), isNull);

        verify(
          () => browser.authenticate(
            startUrl: Uri.parse(
              'http://backend.test/auth/twitch/start?challenge=challenge-test',
            ),
            callbackScheme: 'klimmeck',
          ),
        ).called(1);
        service.dispose();
      });
    });

    test('redeems the ticket, persists the session and authenticates', () {
      fakeAsync((async) {
        browserReturns(_ticketCallback);
        exchangeAnswers(() async => _loginSession);
        refreshAnswers([buildAuthSession(refreshToken: 'rotated')]);
        final service = buildService(async);

        runLogin(service, async);

        verify(
          () => api.exchangeLoginTicket(
            ticket: 'T',
            codeVerifier: 'verifier-test',
          ),
        ).called(1);
        expect(store.refreshToken, 'login-refresh');
        expect(states, [
          AuthAuthenticated(
            user: _userB,
            accessToken: _loginSession.accessToken,
          ),
        ]);
        expect(tokenNow(service, async), _loginSession.accessToken);

        async.elapse(const Duration(minutes: 14));
        verify(() => api.refreshSession('login-refresh')).called(1);
        service.dispose();
      });
    });

    test('does not go back to AuthBootstrapping', () {
      fakeAsync((async) {
        browserReturns(_ticketCallback);
        exchangeAnswers(() async => _loginSession);
        final service = buildService(async);
        initialize(service, async);

        runLogin(service, async);

        expect(states, [
          const AuthBootstrapping(),
          const AuthUnauthenticated(),
          isA<AuthAuthenticated>(),
        ]);
        service.dispose();
      });
    });

    test('switching account reports the new user', () {
      fakeAsync((async) {
        store = InMemorySessionStore(refreshToken: 'r0');
        refreshAnswers([buildAuthSession(refreshToken: 'r1')]);
        browserReturns(_ticketCallback);
        exchangeAnswers(() async => _loginSession);
        final service = buildService(async);
        initialize(service, async);
        expect(
          states.last,
          isA<AuthAuthenticated>().having(
            (s) => s.user,
            'user',
            buildTestUser(),
          ),
        );

        runLogin(service, async);

        expect(
          states.last,
          AuthAuthenticated(
            user: _userB,
            accessToken: _loginSession.accessToken,
          ),
        );
        expect(store.refreshToken, 'login-refresh');
        service.dispose();
      });
    });
  });

  group('login failures', () {
    void expectLoginError(Object expected, {required void Function() arrange}) {
      fakeAsync((async) {
        store = InMemorySessionStore(refreshToken: 'r0');
        arrange();
        final service = buildService(async);

        expect(runLogin(service, async), expected);
        expect(states, isEmpty);
        expect(store.refreshToken, 'r0');
        service.dispose();
      });
    }

    test('browser cancel is a silent cancellation without exchange', () {
      expectLoginError(
        const LoginCancelledException(),
        arrange: () => browserThrows(const BrowserAuthCancelled()),
      );
      verifyNever(
        () => api.exchangeLoginTicket(
          ticket: any(named: 'ticket'),
          codeVerifier: any(named: 'codeVerifier'),
        ),
      );
    });

    test('access_denied is treated like a cancellation', () {
      expectLoginError(
        const LoginCancelledException(),
        arrange: () => browserReturns('klimmeck://auth?error=access_denied'),
      );
    });

    test('twitch_not_configured means login is unavailable', () {
      expectLoginError(
        const LoginUnavailableException(),
        arrange: () =>
            browserReturns('klimmeck://auth?error=twitch_not_configured'),
      );
    });

    test('a backend error code is surfaced as a failure', () {
      expectLoginError(
        const LoginFailedException('invalid_state'),
        arrange: () => browserReturns('klimmeck://auth?error=invalid_state'),
      );
    });

    test('a malformed callback is surfaced as a failure', () {
      expectLoginError(
        const LoginFailedException('invalid_callback'),
        arrange: () => browserReturns('https://evil.test/auth?ticket=T'),
      );
    });

    test('a browser failure keeps its code', () {
      expectLoginError(
        const LoginFailedException('NO_BROWSER'),
        arrange: () => browserThrows(const BrowserAuthFailure('NO_BROWSER')),
      );
    });

    test('an invalid ticket is surfaced with its code', () {
      expectLoginError(
        const LoginFailedException(loginTicketInvalidCode),
        arrange: () {
          browserReturns(_ticketCallback);
          exchangeAnswers(() async => throw const LoginTicketInvalid());
        },
      );
    });

    test('a transient exchange failure is a network failure', () {
      expectLoginError(
        const LoginFailedException('network'),
        arrange: () {
          browserReturns(_ticketCallback);
          exchangeAnswers(
            () async => throw const TransientAuthFailure('timeout'),
          );
        },
      );
    });
  });

  group('login while a saved session is in retry', () {
    void expectRetryContinues({required void Function() arrangeLogin}) {
      fakeAsync((async) {
        store = InMemorySessionStore(refreshToken: 'r0');
        final recovered = buildAuthSession(refreshToken: 'r1');
        refreshAnswers([const TransientAuthFailure('network'), recovered]);
        arrangeLogin();
        final service = buildService(async);
        initialize(service, async);
        expect(refreshCalls, 1);

        expect(runLogin(service, async), isA<LoginException>());
        expect(store.refreshToken, 'r0');
        expect(states, const [AuthBootstrapping()]);

        async.elapse(const Duration(seconds: 1));
        expect(refreshCalls, 2);
        expect(
          states.last,
          AuthAuthenticated(
            user: buildTestUser(),
            accessToken: recovered.accessToken,
          ),
        );
        expect(store.refreshToken, 'r1');
        service.dispose();
      });
    }

    test('a cancelled login keeps the background retry alive', () {
      expectRetryContinues(
        arrangeLogin: () => browserThrows(const BrowserAuthCancelled()),
      );
    });

    test('an unavailable login keeps the background retry alive', () {
      expectRetryContinues(
        arrangeLogin: () =>
            browserReturns('klimmeck://auth?error=twitch_not_configured'),
      );
    });

    test('a failed ticket exchange keeps the background retry alive', () {
      expectRetryContinues(
        arrangeLogin: () {
          browserReturns(_ticketCallback);
          exchangeAnswers(
            () async => throw const TransientAuthFailure('network'),
          );
        },
      );
    });

    test('a successful login cancels the bootstrap retry', () {
      fakeAsync((async) {
        store = InMemorySessionStore(refreshToken: 'r0');
        refreshAnswers([const TransientAuthFailure('network')]);
        browserReturns(_ticketCallback);
        exchangeAnswers(() async => _loginSession);
        final service = buildService(async);
        initialize(service, async);

        expect(runLogin(service, async), isNull);
        async.elapse(const Duration(minutes: 5));

        expect(refreshCalls, 1);
        expect(store.refreshToken, 'login-refresh');
        expect(
          states.last,
          AuthAuthenticated(
            user: _userB,
            accessToken: _loginSession.accessToken,
          ),
        );
        service.dispose();
      });
    });

    test('a successful login supersedes a refresh still in flight', () {
      fakeAsync((async) {
        store = InMemorySessionStore(refreshToken: 'r0');
        final staleRefresh = Completer<AuthSession>();
        when(
          () => api.refreshSession(any()),
        ).thenAnswer((_) => staleRefresh.future);
        browserReturns(_ticketCallback);
        exchangeAnswers(() async => _loginSession);
        final service = buildService(async);
        initialize(service, async);

        expect(runLogin(service, async), isNull);
        staleRefresh.complete(buildAuthSession(refreshToken: 'stale'));
        async.flushMicrotasks();

        expect(store.refreshToken, 'login-refresh');
        expect(
          states.last,
          AuthAuthenticated(
            user: _userB,
            accessToken: _loginSession.accessToken,
          ),
        );
        expect(tokenNow(service, async), _loginSession.accessToken);
        async.elapse(const Duration(minutes: 5));
        verify(() => api.refreshSession(any())).called(1);
        service.dispose();
      });
    });
  });
}
