import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/auth/auth_session.dart';
import 'package:klimmeck_guide/repository/services/auth/auth.dart';
import 'package:klimmeck_guide/screens/auth/cubit/auth_cubit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/auth_session_fixtures.dart';
import '../../../helpers/fakes/in_memory_session_store.dart';
import '../../../helpers/mocks.dart';

final AuthSession _session = buildAuthSession(
  accessToken: buildTestJwt(),
  refreshToken: 'r1',
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
    when(() => api.refreshSession('r0')).thenAnswer((_) async => _session);
  });

  SessionAuthTokenService startService(
    FakeAsync async, {
    Future<void>? teardownGate,
  }) {
    final service = SessionAuthTokenService(
      api: api,
      store: store,
      browser: MockBrowserAuthenticator(),
      backendBaseUrl: Uri.parse('http://backend.test/'),
      onSessionTeardown: () async {
        teardowns++;
        await teardownGate;
      },
      now: () => testNow.add(async.elapsed),
    );
    service.authStateStream.listen(states.add);
    service.initialize();
    async.flushMicrotasks();
    return service;
  }

  List<AuthUnauthenticated> unauthenticated() =>
      states.whereType<AuthUnauthenticated>().toList();

  group('SessionAuthTokenService terminateSession', () {
    test('is a SessionTerminator', () {
      fakeAsync((async) {
        final service = startService(async);

        expect(service, isA<SessionTerminator>());
        service.dispose();
      });
    });

    test('tears down like a revocation and ends as syncLost', () {
      fakeAsync((async) {
        final service = startService(async);

        service.terminateSession(UnauthenticatedReason.syncLost);
        async.flushMicrotasks();

        expect(teardowns, 1);
        expect(store.refreshToken, isNull);
        expect(
          states.last,
          const AuthUnauthenticated(reason: UnauthenticatedReason.syncLost),
        );
        verifyNever(() => api.logout(any()));
        service.dispose();
      });
    });

    test('terminateSession(accountDeleted) tears down once without calling '
        'the backend (D-06)', () {
      fakeAsync((async) {
        final service = startService(async);

        service.terminateSession(UnauthenticatedReason.accountDeleted);
        async.flushMicrotasks();

        expect(teardowns, 1);
        expect(store.refreshToken, isNull);
        expect(unauthenticated(), [
          const AuthUnauthenticated(
            reason: UnauthenticatedReason.accountDeleted,
          ),
        ]);
        verifyNever(() => api.logout(any()));
        verifyNever(() => api.refreshSession('r1'));
        service.dispose();
      });
    });

    test('a second terminateSession after accountDeleted is a no-op '
        '(D-06)', () {
      fakeAsync((async) {
        final service = startService(async);
        service.terminateSession(UnauthenticatedReason.accountDeleted);
        async.flushMicrotasks();

        service.terminateSession(UnauthenticatedReason.syncLost);
        async.flushMicrotasks();

        expect(teardowns, 1);
        expect(unauthenticated(), [
          const AuthUnauthenticated(
            reason: UnauthenticatedReason.accountDeleted,
          ),
        ]);
        service.dispose();
      });
    });

    test('does nothing while unauthenticated', () {
      fakeAsync((async) {
        store = InMemorySessionStore();
        final service = startService(async);
        final before = states.length;

        service.terminateSession(UnauthenticatedReason.syncLost);
        async.flushMicrotasks();

        expect(teardowns, 0);
        expect(states.length, before);
        service.dispose();
      });
    });

    test('does nothing while a logout is in flight and leaves one '
        'signedOut terminal state', () {
      fakeAsync((async) {
        final logoutGate = Completer<void>();
        when(() => api.logout(any())).thenAnswer((_) => logoutGate.future);
        final service = startService(async);
        service.logout();
        async.flushMicrotasks();

        service.terminateSession(UnauthenticatedReason.syncLost);
        async.flushMicrotasks();
        logoutGate.complete();
        async.flushMicrotasks();

        expect(teardowns, 1);
        expect(unauthenticated(), [
          const AuthUnauthenticated(reason: UnauthenticatedReason.signedOut),
        ]);
        service.dispose();
      });
    });

    test('a logout after the accountDeleted landing keeps it: no signedOut '
        'over it, no backend logout (U-1)', () {
      fakeAsync((async) {
        final service = startService(async);
        service.terminateSession(UnauthenticatedReason.accountDeleted);
        async.flushMicrotasks();

        service.logout();
        async.flushMicrotasks();

        expect(teardowns, 1);
        expect(store.clears, 1);
        expect(unauthenticated(), [
          const AuthUnauthenticated(
            reason: UnauthenticatedReason.accountDeleted,
          ),
        ]);
        verifyNever(() => api.logout(any()));
        service.dispose();
      });
    });

    test('a logout waiting for the push unregister when accountDeleted '
        'arrives ends as accountDeleted, without a backend logout (U-1)', () {
      fakeAsync((async) {
        final unregisterGate = Completer<void>();
        final pushCleanup = MockPushSessionCleanup();
        when(
          () => pushCleanup.unregister(),
        ).thenAnswer((_) => unregisterGate.future);
        final service = startService(async);
        final cubit = AuthCubit(service, pushCleanup: pushCleanup);
        var isLogoutDone = false;
        cubit.logout().then<void>((_) => isLogoutDone = true);
        async.flushMicrotasks();

        service.terminateSession(UnauthenticatedReason.accountDeleted);
        async.flushMicrotasks();
        unregisterGate.complete();
        async.flushMicrotasks();

        expect(isLogoutDone, isTrue);
        expect(teardowns, 1);
        expect(unauthenticated(), [
          const AuthUnauthenticated(
            reason: UnauthenticatedReason.accountDeleted,
          ),
        ]);
        verifyNever(() => api.logout(any()));
        cubit.close();
        service.dispose();
      });
    });

    test('accountDeleted arriving while the backend logout is out lands as '
        'signedOut: the logout already owns the session (U-1)', () {
      fakeAsync((async) {
        final logoutGate = Completer<void>();
        when(() => api.logout(any())).thenAnswer((_) => logoutGate.future);
        final service = startService(async);
        service.logout();
        async.flushMicrotasks();
        verify(() => api.logout(_session.accessToken)).called(1);

        service.terminateSession(UnauthenticatedReason.accountDeleted);
        async.flushMicrotasks();
        logoutGate.complete();
        async.flushMicrotasks();

        expect(teardowns, 1);
        expect(unauthenticated(), [
          const AuthUnauthenticated(reason: UnauthenticatedReason.signedOut),
        ]);
        verifyNever(() => api.logout(any()));
        service.dispose();
      });
    });

    test('overlapping terminations run one teardown and one terminal '
        'state', () {
      fakeAsync((async) {
        final service = startService(async);

        service.terminateSession(UnauthenticatedReason.syncLost);
        service.terminateSession(UnauthenticatedReason.syncLost);
        async.flushMicrotasks();

        expect(teardowns, 1);
        expect(unauthenticated(), [
          const AuthUnauthenticated(reason: UnauthenticatedReason.syncLost),
        ]);
        service.dispose();
      });
    });

    test('a syncLost termination during a newLogin refusal teardown keeps '
        'the first reason: one teardown, one terminal state (D-12)', () {
      fakeAsync((async) {
        final teardownGate = Completer<void>();
        when(() => api.refreshSession('r1')).thenAnswer(
          (_) async => throw const SessionRejected(
            sessionRevokedCode,
            reason: sessionRevokedReasonNewLogin,
          ),
        );
        final service = startService(async, teardownGate: teardownGate.future);
        service.recoverFromUnauthorized(rejectedToken: _session.accessToken);
        async.flushMicrotasks();

        service.terminateSession(UnauthenticatedReason.syncLost);
        async.flushMicrotasks();
        teardownGate.complete();
        async.flushMicrotasks();

        expect(teardowns, 1);
        expect(unauthenticated(), [
          const AuthUnauthenticated(
            reason: UnauthenticatedReason.replacedByNewLogin,
          ),
        ]);
        service.dispose();
      });
    });
  });
}
