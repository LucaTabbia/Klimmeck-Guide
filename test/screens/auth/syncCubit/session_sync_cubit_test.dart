import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:klimmeck_guide/models/user.dart';
import 'package:klimmeck_guide/repository/services/graphql/graphql_sync_exceptions.dart';
import 'package:klimmeck_guide/repository/services/sync/app_lifecycle_events.dart';
import 'package:klimmeck_guide/repository/services/sync/sync_watchdog.dart';
import 'package:klimmeck_guide/screens/auth/syncCubit/session_sync_cubit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/auth_fixtures.dart';
import '../../../helpers/mocks.dart';

class _FakeLifecycle implements AppLifecycleEvents {
  final StreamController<void> background = StreamController<void>.broadcast();
  final StreamController<void> foreground = StreamController<void>.broadcast();

  @override
  Stream<void> get backgrounded => background.stream;

  @override
  Stream<void> get foregrounded => foreground.stream;

  bool get hasListeners => background.hasListener || foreground.hasListener;
}

SubscriptionStreamException _streamError(String code) =>
    SubscriptionStreamException(operation: 'userUpdated', code: code);

OperationException _operationError(String code) => OperationException(
  graphqlErrors: [
    GraphQLError(message: 'denied', extensions: {'code': code}),
  ],
);

class _Harness {
  _Harness() {
    when(() => api.subscribeToUser()).thenAnswer((_) {
      final controller = StreamController<User>();
      userStreams.add(controller);
      return controller.stream;
    });
    when(() => auth.adoptUser(any())).thenReturn(true);
    when(() => api.getMe()).thenAnswer((_) => Completer<User>().future);
    watchdog = SyncWatchdog(onExpired: () async => expiries++);
    cubit = SessionSyncCubit(
      api: api,
      auth: auth,
      watchdog: watchdog,
      connection: connection.stream,
      lifecycle: lifecycle,
      userRefreshRequests: refreshRequests.stream,
    );
    cubit.stream.listen(states.add);
  }

  final MockKlimmeckGraphQl api = MockKlimmeckGraphQl();
  final MockAuthTokenService auth = MockAuthTokenService();
  final StreamController<bool> connection = StreamController<bool>();
  final _FakeLifecycle lifecycle = _FakeLifecycle();
  final StreamController<void> refreshRequests =
      StreamController<void>.broadcast();
  final List<StreamController<User>> userStreams = [];
  final List<SessionSyncState> states = [];
  late final SyncWatchdog watchdog;
  late final SessionSyncCubit cubit;
  int expiries = 0;

  StreamController<User> get latestStream => userStreams.last;

  void dispose() {
    watchdog.dispose();
    cubit.close();
  }
}

void withHarness(
  String description,
  void Function(_Harness h, FakeAsync async) body,
) {
  test(description, () {
    fakeAsync((async) {
      final harness = _Harness();
      body(harness, async);
      harness.dispose();
      async.flushMicrotasks();
    });
  });
}

void main() {
  setUpAll(() => registerFallbackValue(buildTestUser()));

  group('user stream', () {
    withHarness('start subscribes once and never polls', (h, async) {
      h.cubit.start();
      async.elapse(const Duration(minutes: 1));

      verify(() => h.api.subscribeToUser()).called(1);
      verifyNever(() => h.api.getMe());
    });

    withHarness('an event is adopted through the service and goes live', (
      h,
      async,
    ) {
      final user = buildTestUserWithCharacter();
      h.cubit.start();

      h.latestStream.add(user);
      async.flushMicrotasks();

      verify(() => h.auth.adoptUser(user)).called(1);
      expect(h.states, [const SessionSyncLive()]);
      expect(h.watchdog.isDegraded, isFalse);
    });

    withHarness('an event of another identity is dropped without a state', (
      h,
      async,
    ) {
      when(() => h.auth.adoptUser(any())).thenReturn(false);
      h.cubit.start();

      h.latestStream.add(buildTestUser());
      async.flushMicrotasks();

      verify(() => h.auth.adoptUser(any())).called(1);
      expect(h.states, isEmpty);
      expect(h.cubit.state, const SessionSyncStarting());
    });

    withHarness('a stream error resubscribes with growing backoff', (h, async) {
      h.cubit.start();

      h.latestStream.addError(_streamError('INTERNAL_SERVER_ERROR'));
      async.flushMicrotasks();

      expect(h.cubit.state, const SessionSyncRecovering());
      expect(h.watchdog.isDegraded, isTrue);
      async.elapse(const Duration(milliseconds: 999));
      verify(() => h.api.subscribeToUser()).called(1);
      async.elapse(const Duration(milliseconds: 1));
      verify(() => h.api.subscribeToUser()).called(1);

      h.latestStream.addError(_streamError('INTERNAL_SERVER_ERROR'));
      async.flushMicrotasks();
      async.elapse(const Duration(milliseconds: 1999));
      verifyNever(() => h.api.subscribeToUser());
      async.elapse(const Duration(milliseconds: 1));
      verify(() => h.api.subscribeToUser()).called(1);
    });

    withHarness('an event resets the backoff and returns to live', (h, async) {
      h.cubit.start();
      h.latestStream.addError(_streamError('INTERNAL_SERVER_ERROR'));
      async.elapse(const Duration(seconds: 1));
      h.latestStream.addError(_streamError('INTERNAL_SERVER_ERROR'));
      async.elapse(const Duration(seconds: 2));
      expect(h.userStreams, hasLength(3));

      h.latestStream.add(buildTestUserWithCharacter());
      async.flushMicrotasks();
      expect(h.cubit.state, const SessionSyncLive());
      expect(h.watchdog.isDegraded, isFalse);

      h.latestStream.addError(_streamError('INTERNAL_SERVER_ERROR'));
      async.elapse(const Duration(seconds: 1));
      expect(h.userStreams, hasLength(4));
    });

    withHarness('a completed stream resubscribes like an error', (h, async) {
      h.cubit.start();

      h.latestStream.close();
      async.flushMicrotasks();

      expect(h.cubit.state, const SessionSyncRecovering());
      async.elapse(const Duration(seconds: 1));
      expect(h.userStreams, hasLength(2));
    });

    withHarness('a malformed event follows the silent backoff path', (
      h,
      async,
    ) {
      h.cubit.start();

      h.latestStream.addError(const FormatException('bad user'));
      async.flushMicrotasks();

      expect(h.cubit.state, const SessionSyncRecovering());
      async.elapse(const Duration(seconds: 1));
      expect(h.userStreams, hasLength(2));
    });

    for (final code in ['FORBIDDEN', 'NOT_FOUND']) {
      withHarness('$code is terminal: one refetch and no resubscribe', (
        h,
        async,
      ) {
        when(
          () => h.api.getMe(),
        ).thenAnswer((_) async => buildTestUserWithCharacter());
        h.cubit.start();

        h.latestStream.addError(_streamError(code));
        h.latestStream.close();
        async.elapse(const Duration(minutes: 10));

        verify(() => h.api.subscribeToUser()).called(1);
        verify(() => h.api.getMe()).called(1);
      });
    }

    withHarness('the socket state feeds the watchdog', (h, async) {
      h.cubit.start();
      h.latestStream.add(buildTestUserWithCharacter());
      async.flushMicrotasks();

      h.connection.add(false);
      async.flushMicrotasks();
      expect(h.watchdog.isDegraded, isTrue);

      h.connection.add(true);
      async.flushMicrotasks();
      expect(h.watchdog.isDegraded, isFalse);
    });

    withHarness('an idle healthy session never expires', (h, async) {
      h.cubit.start();
      h.connection.add(true);
      h.latestStream.add(buildTestUserWithCharacter());
      async.elapse(const Duration(minutes: 10));

      expect(h.expiries, 0);
    });

    withHarness('close releases every listener and timer', (h, async) {
      h.cubit.start();
      h.connection.add(true);
      final stream = h.latestStream;
      stream.addError(_streamError('INTERNAL_SERVER_ERROR'));
      async.flushMicrotasks();

      h.cubit.close();
      async.flushMicrotasks();

      expect(h.connection.hasListener, isFalse);
      expect(h.lifecycle.hasListeners, isFalse);
      expect(h.refreshRequests.hasListener, isFalse);
      expect(stream.hasListener, isFalse);
      expect(async.pendingTimers, isEmpty);
    });

    withHarness('a late event after close adopts nothing', (h, async) {
      h.cubit.start();
      final stream = h.latestStream;
      h.cubit.close();
      async.flushMicrotasks();

      stream.add(buildTestUserWithCharacter());
      async.flushMicrotasks();

      verifyNever(() => h.auth.adoptUser(any()));
    });
  });

  blocTest<SessionSyncCubit, SessionSyncState>(
    'emits live once for a burst of equal events',
    build: () {
      final api = MockKlimmeckGraphQl();
      final auth = MockAuthTokenService();
      final user = buildTestUserWithCharacter();
      when(() => api.subscribeToUser()).thenAnswer((_) => Stream.value(user));
      when(() => auth.adoptUser(any())).thenReturn(true);
      return SessionSyncCubit(
        api: api,
        auth: auth,
        watchdog: SyncWatchdog(onExpired: () async {}),
        connection: const Stream<bool>.empty(),
        lifecycle: _FakeLifecycle(),
        userRefreshRequests: const Stream<void>.empty(),
      );
    },
    act: (cubit) => cubit.start(),
    expect: () => [const SessionSyncLive()],
  );
}
