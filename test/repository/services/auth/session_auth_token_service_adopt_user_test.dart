import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/auth/auth_session.dart';
import 'package:klimmeck_guide/models/auth/login_challenge.dart';
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

final User _user = buildTestUser();
final AuthSession _session = buildAuthSession(
  accessToken: buildTestJwt(subject: testUserId),
  refreshToken: 'login-refresh',
  user: _user,
);

void main() {
  late MockBackendAuthApi api;
  late MockBrowserAuthenticator browser;
  late List<AuthState> states;

  setUpAll(() => registerFallbackValue(Uri()));

  setUp(() {
    api = MockBackendAuthApi();
    browser = MockBrowserAuthenticator();
    states = [];
    when(
      () => browser.authenticate(
        startUrl: any(named: 'startUrl'),
        callbackScheme: any(named: 'callbackScheme'),
      ),
    ).thenAnswer((_) async => _ticketCallback);
    when(
      () => api.exchangeLoginTicket(
        ticket: any(named: 'ticket'),
        codeVerifier: any(named: 'codeVerifier'),
      ),
    ).thenAnswer((_) async => _session);
    when(
      () => api.refreshSession(any()),
    ).thenAnswer((_) async => buildAuthSession(refreshToken: 'rotated'));
  });

  SessionAuthTokenService buildService(FakeAsync async) {
    final service = SessionAuthTokenService(
      api: api,
      store: InMemorySessionStore(),
      browser: browser,
      backendBaseUrl: Uri.parse('http://backend.test/'),
      onSessionTeardown: () async {},
      now: () => testNow.add(async.elapsed),
      createChallenge: () => _challenge,
    );
    service.authStateStream.listen(states.add);
    return service;
  }

  void login(SessionAuthTokenService service, FakeAsync async) {
    service.login();
    async.flushMicrotasks();
  }

  test('re-emits the adopted user with the current access token', () {
    fakeAsync((async) {
      final service = buildService(async);
      login(service, async);
      final adopted = buildTestUserWithCharacter();

      final accepted = service.adoptUser(adopted);
      async.flushMicrotasks();

      expect(accepted, isTrue);
      expect(
        states.last,
        AuthAuthenticated(user: adopted, accessToken: _session.accessToken),
      );
      service.dispose();
    });
  });

  test('keeps the adopted user for listeners attached afterwards', () {
    fakeAsync((async) {
      final service = buildService(async);
      login(service, async);
      final adopted = buildTestUserWithCharacter();
      service.adoptUser(adopted);
      async.elapse(const Duration(minutes: 14));

      final lateStates = <AuthState>[];
      service.authStateStream.listen(lateStates.add);
      async.flushMicrotasks();

      expect(
        lateStates.last,
        isA<AuthAuthenticated>().having((s) => s.user, 'user', adopted),
      );
      service.dispose();
    });
  });

  test('refuses a user adopted before authentication', () {
    fakeAsync((async) {
      final service = buildService(async);

      final accepted = service.adoptUser(buildTestUserWithCharacter());
      async.flushMicrotasks();

      expect(accepted, isFalse);
      expect(states, isEmpty);
      service.dispose();
    });
  });

  test('refuses a user with a different id', () {
    fakeAsync((async) {
      final service = buildService(async);
      login(service, async);
      final emitted = states.length;

      final accepted = service.adoptUser(
        buildTestUserWithCharacter().copyWith(id: 'other'),
      );
      async.flushMicrotasks();

      expect(accepted, isFalse);
      expect(states, hasLength(emitted));
      expect((states.last as AuthAuthenticated).user.currentCharacter, isNull);
      service.dispose();
    });
  });
}
