import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/auth/auth_session.dart';
import 'package:klimmeck_guide/repository/services/auth/auth.dart';
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

  SessionAuthTokenService startService(FakeAsync async) {
    final service = SessionAuthTokenService(
      api: api,
      store: store,
      browser: MockBrowserAuthenticator(),
      backendBaseUrl: Uri.parse('http://backend.test/'),
      onSessionTeardown: () async => teardowns++,
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
  });
}
