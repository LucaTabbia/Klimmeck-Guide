import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/auth/login_challenge.dart';
import 'package:klimmeck_guide/repository/account_deletion_failure.dart';
import 'package:klimmeck_guide/repository/account_deletion_repository.dart';
import 'package:klimmeck_guide/repository/services/auth/auth.dart';

import '../helpers/auth_fixtures.dart';
import '../helpers/auth_session_fixtures.dart';
import '../helpers/fakes/fake_account_deletion_api.dart';
import '../helpers/fakes/fake_session_backend.dart';
import '../helpers/fakes/in_memory_session_store.dart';

const LoginChallenge _challenge = LoginChallenge(
  codeVerifier: 'verifier-test',
  codeChallenge: 'challenge-test',
);

/// La cancellazione del proprio account sul servizio di sessione reale: una
/// revoca (refresh o socket chiuso con 4409) che arriva mentre la
/// cancellazione è in volo non trasforma l'atterraggio in «sessione scaduta»
/// (research Pitfall 1, D-06, D-18).
void main() {
  late _LogoutCountingBackend backend;
  late SessionAuthTokenService service;
  late FakeAccountDeletionApi api;
  late AccountDeletionRepository repository;
  late List<AuthState> states;
  late StreamSubscription<AuthState> recorder;

  setUp(() async {
    backend = _LogoutCountingBackend();
    service = SessionAuthTokenService(
      api: backend,
      store: InMemorySessionStore(),
      browser: const _TicketBrowser(),
      backendBaseUrl: Uri.parse('http://127.0.0.1/'),
      onSessionTeardown: () async {},
      now: () => testNow,
      createChallenge: () => _challenge,
    );
    states = [];
    recorder = service.authStateStream.listen(states.add);
    api = FakeAccountDeletionApi();
    repository = AccountDeletionRepository(api: api, terminator: service);
    await service.login(acceptedLegalVersion: 'v-test');
    await pumpEventQueue();
  });

  tearDown(() async {
    await recorder.cancel();
    service.dispose();
  });

  String currentAccessToken() => (states.last as AuthAuthenticated).accessToken;

  /// Ciò che fa il recupero del socket chiuso con 4409: il BE ha revocato
  /// ogni sessione con il motivo, il refresh del token rifiutato lo legge.
  Future<String?> revokeAndRecover(String rejectedToken) {
    backend.revokeAll(sessionRevokedReasonAccountDeleted);
    return service.recoverFromUnauthorized(rejectedToken: rejectedToken);
  }

  test('a revocation that lands while the deletion is in flight ends once as '
      'accountDeleted (Pitfall 1, D-06, D-18)', () async {
    final token = currentAccessToken();
    final authenticatedStates = states.length;
    api.beforeDeleteMyAccountReturns = () async {
      await revokeAndRecover(token);
    };

    await repository.deleteOwnAccount();
    await pumpEventQueue();

    expect(states.skip(authenticatedStates), [
      const AuthUnauthenticated(reason: UnauthenticatedReason.accountDeleted),
    ]);
    expect(backend.logoutCalls, 0);
  });

  test(
    'the deletion answer before the socket close ends once as accountDeleted',
    () async {
      final token = currentAccessToken();
      final authenticatedStates = states.length;

      await repository.deleteOwnAccount();
      final recovered = await revokeAndRecover(token);
      await pumpEventQueue();

      expect(recovered, isNull);
      expect(states.skip(authenticatedStates), [
        const AuthUnauthenticated(reason: UnauthenticatedReason.accountDeleted),
      ]);
      expect(backend.logoutCalls, 0);
    },
  );

  test('a failed deletion leaves the session authenticated', () async {
    api.error = operationExceptionWithCode('INNKEEPER_ACCOUNT_PROTECTED');

    await expectLater(
      repository.deleteOwnAccount(),
      throwsA(isA<AccountDeletionException>()),
    );
    await pumpEventQueue();

    expect(states.last, isA<AuthAuthenticated>());
    expect(backend.logoutCalls, 0);
  });
}

/// BE di sessione che conta i logout: dopo una cancellazione non ne arriva
/// nessuno (D-06).
class _LogoutCountingBackend extends FakeSessionBackend {
  _LogoutCountingBackend() : super(user: buildTestUser());

  int logoutCalls = 0;

  @override
  Future<void> logout(String accessToken) {
    logoutCalls++;
    return super.logout(accessToken);
  }
}

/// Browser che risponde subito con il ticket di login.
class _TicketBrowser implements BrowserAuthenticator {
  const _TicketBrowser();

  @override
  Future<String> authenticate({
    required Uri startUrl,
    required String callbackScheme,
  }) async => 'klimmeck://auth?ticket=T';
}
