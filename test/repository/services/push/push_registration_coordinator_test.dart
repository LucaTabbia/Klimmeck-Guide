import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/repository/push_device_failure.dart';
import 'package:klimmeck_guide/repository/services/auth/auth_token_service.dart';
import 'package:klimmeck_guide/repository/services/push/push_registration_coordinator.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/auth_fixtures.dart';
import '../../../helpers/fakes/fake_push_messaging_port.dart';
import '../../../helpers/fakes/in_memory_active_user_store.dart';
import '../../../helpers/fakes/in_memory_device_identity_store.dart';
import '../../../helpers/fakes/recording_local_notifications_port.dart';
import '../../../helpers/mocks.dart';

AuthAuthenticated _authenticated(String userId) => AuthAuthenticated(
  user: buildTestUser().copyWith(id: userId),
  accessToken: 'access',
);

/// Collaboratori del coordinator creati dentro la zona `fakeAsync` del test.
class _Harness {
  _Harness() {
    when(
      () => repository.register(
        deviceId: any(named: 'deviceId'),
        token: any(named: 'token'),
      ),
    ).thenAnswer((_) async {});
    when(() => repository.unregister(any())).thenAnswer((_) async {});
    coordinator.start();
  }

  final StreamController<AuthState> authStates =
      StreamController<AuthState>.broadcast();
  final FakePushMessagingPort messaging = FakePushMessagingPort();
  final MockPushDeviceRepository repository = MockPushDeviceRepository();
  final InMemoryDeviceIdentityStore deviceIdentity =
      InMemoryDeviceIdentityStore();
  final InMemoryActiveUserStore activeUser = InMemoryActiveUserStore();
  final RecordingLocalNotificationsPort localNotifications =
      RecordingLocalNotificationsPort();

  late final PushRegistrationCoordinator coordinator =
      PushRegistrationCoordinator(
        authStates: authStates.stream,
        messaging: messaging,
        repository: repository,
        deviceIdentity: deviceIdentity,
        activeUser: activeUser,
        localNotifications: localNotifications,
      );

  void failRegistration(PushDeviceFailure failure) {
    when(
      () => repository.register(
        deviceId: any(named: 'deviceId'),
        token: any(named: 'token'),
      ),
    ).thenAnswer((_) async => throw PushDeviceException(failure));
  }

  void emit(FakeAsync async, AuthState state) {
    authStates.add(state);
    async.flushMicrotasks();
  }

  void refreshToken(FakeAsync async, String token) {
    messaging.refreshes.add(token);
    async.flushMicrotasks();
  }

  void verifyRegistered(String token, {int times = 1}) => verify(
    () => repository.register(deviceId: 'device-1', token: token),
  ).called(times);

  void verifyNoRegistration() => verifyNever(
    () => repository.register(
      deviceId: any(named: 'deviceId'),
      token: any(named: 'token'),
    ),
  );

  int registrationCalls() => verify(
    () => repository.register(
      deviceId: any(named: 'deviceId'),
      token: any(named: 'token'),
    ),
  ).callCount;
}

void main() {
  group('registration', () {
    test('an authenticated session registers the device once', () {
      fakeAsync((async) {
        final harness = _Harness();
        harness.emit(async, _authenticated('u-1'));

        harness.verifyRegistered('token-1');
        expect(harness.activeUser.writes, ['u-1']);
      });
    });

    test('re-emissions for the same user do not register again', () {
      fakeAsync((async) {
        final harness = _Harness();
        harness.emit(async, _authenticated('u-1'));
        harness.emit(async, _authenticated('u-1'));
        harness.emit(async, _authenticated('u-1'));

        harness.verifyRegistered('token-1');
        expect(harness.activeUser.writes, ['u-1']);
      });
    });

    test('bootstrapping does nothing', () {
      fakeAsync((async) {
        final harness = _Harness();
        harness.emit(async, const AuthBootstrapping());

        harness.verifyNoRegistration();
        expect(harness.activeUser.writes, isEmpty);
        expect(harness.activeUser.clears, 0);
      });
    });

    test('a different user registers again and is mirrored', () {
      fakeAsync((async) {
        final harness = _Harness();
        harness.emit(async, _authenticated('u-1'));
        harness.emit(async, _authenticated('u-2'));

        harness.verifyRegistered('token-1', times: 2);
        expect(harness.activeUser.writes, ['u-1', 'u-2']);
      });
    });
  });

  group('token refresh', () {
    test('a refresh while authenticated registers the new token', () {
      fakeAsync((async) {
        final harness = _Harness();
        harness.emit(async, _authenticated('u-1'));
        harness.refreshToken(async, 'token-2');

        harness.verifyRegistered('token-2');
      });
    });

    test('a refresh without a session does not register', () {
      fakeAsync((async) {
        final harness = _Harness();
        harness.refreshToken(async, 'token-2');

        harness.verifyNoRegistration();
      });
    });

    test('a refresh after the session ended does not register', () {
      fakeAsync((async) {
        final harness = _Harness();
        harness.emit(async, _authenticated('u-1'));
        harness.emit(async, const AuthUnauthenticated());
        harness.refreshToken(async, 'token-2');

        verifyNever(
          () => harness.repository.register(
            deviceId: any(named: 'deviceId'),
            token: 'token-2',
          ),
        );
      });
    });

    test('no token at login waits for the refresh without retrying', () {
      fakeAsync((async) {
        final harness = _Harness()..messaging.currentToken = null;
        harness.emit(async, _authenticated('u-1'));
        async.elapse(const Duration(minutes: 2));

        harness.verifyNoRegistration();
        expect(harness.messaging.tokenCalls, 1);

        harness.refreshToken(async, 'token-2');
        harness.verifyRegistered('token-2');
      });
    });

    test('a token not yet available is retried after one second', () {
      fakeAsync((async) {
        final harness = _Harness()
          ..messaging.tokenFailure = StateError('SERVICE_NOT_AVAILABLE');
        harness.emit(async, _authenticated('u-1'));
        harness.verifyNoRegistration();

        harness.messaging.tokenFailure = null;
        async.elapse(const Duration(seconds: 1));

        harness.verifyRegistered('token-1');
      });
    });
  });

  group('silent retry', () {
    test('transient failures stop after five attempts', () {
      fakeAsync((async) {
        final harness = _Harness()
          ..failRegistration(PushDeviceFailure.connection);
        harness.emit(async, _authenticated('u-1'));
        async.elapse(const Duration(minutes: 2));
        expect(harness.registrationCalls(), 5);

        async.elapse(const Duration(minutes: 5));
        harness.verifyNoRegistration();
      });
    });

    for (final failure in [
      PushDeviceFailure.invalidToken,
      PushDeviceFailure.invalidDeviceId,
      PushDeviceFailure.unauthenticated,
    ]) {
      test('${failure.name} stops after a single attempt', () {
        fakeAsync((async) {
          final harness = _Harness()..failRegistration(failure);
          harness.emit(async, _authenticated('u-1'));
          async.elapse(const Duration(minutes: 2));

          expect(harness.registrationCalls(), 1);
        });
      });
    }
  });

  group('unregister', () {
    test('removes the device and suspends later refreshes', () {
      fakeAsync((async) {
        final harness = _Harness();
        harness.emit(async, _authenticated('u-1'));
        harness.coordinator.unregister();
        async.flushMicrotasks();

        verify(() => harness.repository.unregister('device-1')).called(1);

        harness.refreshToken(async, 'token-2');
        verifyNever(
          () => harness.repository.register(
            deviceId: any(named: 'deviceId'),
            token: 'token-2',
          ),
        );
      });
    });

    test('cancels a pending retry so it cannot register again', () {
      fakeAsync((async) {
        final harness = _Harness()
          ..failRegistration(PushDeviceFailure.connection);
        harness.emit(async, _authenticated('u-1'));
        expect(harness.registrationCalls(), 1);

        harness.coordinator.unregister();
        async.elapse(const Duration(minutes: 2));

        harness.verifyNoRegistration();
        verify(() => harness.repository.unregister('device-1')).called(1);
      });
    });

    test('without a session makes no backend call', () {
      fakeAsync((async) {
        final harness = _Harness();
        harness.coordinator.unregister();
        async.flushMicrotasks();

        verifyNever(() => harness.repository.unregister(any()));
      });
    });

    test('a failing removal still completes normally', () {
      fakeAsync((async) {
        final harness = _Harness();
        when(() => harness.repository.unregister(any())).thenAnswer(
          (_) async =>
              throw const PushDeviceException(PushDeviceFailure.connection),
        );
        harness.emit(async, _authenticated('u-1'));
        var completed = false;
        Object? failure;
        harness.coordinator.unregister().then(
          (_) => completed = true,
          onError: (Object error) => failure = error,
        );
        async.flushMicrotasks();

        expect(completed, isTrue);
        expect(failure, isNull);
      });
    });

    test('with push disabled skips the network and any wait', () {
      fakeAsync((async) {
        final harness = _Harness()..messaging.currentToken = null;
        harness.emit(async, _authenticated('u-1'));
        var completed = false;
        harness.coordinator.unregister().then((_) => completed = true);
        async.flushMicrotasks();

        expect(completed, isTrue);
        expect(async.pendingTimers, isEmpty);
        verifyNever(() => harness.repository.unregister(any()));
      });
    });

    test('once a token was seen removes the device even after a failure', () {
      fakeAsync((async) {
        final harness = _Harness()
          ..failRegistration(PushDeviceFailure.connection);
        harness.emit(async, _authenticated('u-1'));
        harness.coordinator.unregister();
        async.flushMicrotasks();

        verify(() => harness.repository.unregister('device-1')).called(1);
      });
    });
  });

  group('session end', () {
    test('clears the active user and the tray after a session', () {
      fakeAsync((async) {
        final harness = _Harness();
        harness.emit(async, _authenticated('u-1'));
        harness.emit(async, const AuthUnauthenticated());

        expect(harness.activeUser.clears, 1);
        expect(harness.localNotifications.cancelAllCalls, 1);
      });
    });

    test('a new session after the end registers again', () {
      fakeAsync((async) {
        final harness = _Harness();
        harness.emit(async, _authenticated('u-1'));
        harness.coordinator.unregister();
        async.flushMicrotasks();
        harness.emit(async, const AuthUnauthenticated());
        harness.emit(async, _authenticated('u-1'));

        harness.verifyRegistered('token-1', times: 2);
      });
    });

    test('at cold start clears the mirror but leaves the tray alone', () {
      fakeAsync((async) {
        final harness = _Harness();
        harness.emit(async, const AuthUnauthenticated());

        expect(harness.activeUser.clears, 1);
        expect(harness.localNotifications.cancelAllCalls, 0);
      });
    });
  });

  test('after dispose auth events and refreshes are ignored', () {
    fakeAsync((async) {
      final harness = _Harness();
      harness.coordinator.dispose();
      async.flushMicrotasks();
      harness.emit(async, _authenticated('u-1'));
      harness.refreshToken(async, 'token-2');

      harness.verifyNoRegistration();
      expect(harness.activeUser.writes, isEmpty);
    });
  });
}
