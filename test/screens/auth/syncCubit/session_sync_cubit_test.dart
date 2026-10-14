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

class FakeLifecycle implements AppLifecycleEvents {
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

class SyncHarness {
  SyncHarness() {
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
  final FakeLifecycle lifecycle = FakeLifecycle();
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
  void Function(SyncHarness h, FakeAsync async) body,
) {
  test(description, () {
    fakeAsync((async) {
      final harness = SyncHarness();
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

    withHarness(
      'a stream that completes after the session end is not reopened',
      (h, async) {
        h.cubit.start();
        h.connection.add(false);
        async.elapse(const Duration(minutes: 3));
        expect(h.watchdog.isLatched, isTrue);

        h.latestStream.close();
        async.elapse(const Duration(minutes: 1));

        expect(h.userStreams, hasLength(1));
        expect(h.states, isNot(contains(const SessionSyncRecovering())));
      },
    );

    withHarness('a pending resubscribe is dropped once the session ends', (
      h,
      async,
    ) {
      h.cubit.start();
      h.latestStream.close();
      async.flushMicrotasks();
      expect(h.cubit.state, const SessionSyncRecovering());

      h.watchdog.dispose();
      async.elapse(const Duration(minutes: 1));

      expect(h.userStreams, hasLength(1));
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

  group('resume and refresh requests', () {
    withHarness('a foreground refetches me and adopts it', (h, async) {
      final user = buildTestUserWithCharacter();
      when(() => h.api.getMe()).thenAnswer((_) async => user);
      h.cubit.start();

      h.lifecycle.foreground.add(null);
      async.flushMicrotasks();

      verify(() => h.api.getMe()).called(1);
      verify(() => h.auth.adoptUser(user)).called(1);
    });

    withHarness('a successful refetch restarts the degraded window', (
      h,
      async,
    ) {
      when(
        () => h.api.getMe(),
      ).thenAnswer((_) async => buildTestUserWithCharacter());
      h.cubit.start();
      h.connection.add(false);
      async.elapse(const Duration(minutes: 2));

      h.lifecycle.foreground.add(null);
      async.elapse(const Duration(minutes: 2, seconds: 59));
      expect(h.expiries, 0);

      async.elapse(const Duration(seconds: 1));
      expect(h.expiries, 1);
    });

    withHarness('a refetch overtaken by a live event is discarded', (h, async) {
      final pending = Completer<User>();
      when(() => h.api.getMe()).thenAnswer((_) => pending.future);
      final live = buildTestUserWithCharacter();
      h.cubit.start();
      h.lifecycle.foreground.add(null);
      async.flushMicrotasks();

      h.latestStream.add(live);
      async.flushMicrotasks();
      pending.complete(buildTestUser());
      async.flushMicrotasks();

      verify(() => h.auth.adoptUser(any())).called(1);
      verifyNever(() => h.auth.adoptUser(buildTestUser()));
    });

    withHarness('a failing refetch retries silently until it succeeds', (
      h,
      async,
    ) {
      var calls = 0;
      when(() => h.api.getMe()).thenAnswer((_) async {
        if (++calls <= 2) throw OperationException();
        return buildTestUserWithCharacter();
      });
      h.cubit.start();

      h.lifecycle.foreground.add(null);
      async.elapse(const Duration(milliseconds: 2999));
      verifyNever(() => h.auth.adoptUser(any()));
      async.elapse(const Duration(milliseconds: 1));

      verify(() => h.api.getMe()).called(3);
      verify(() => h.auth.adoptUser(any())).called(1);
      expect(h.states, isEmpty);
    });

    withHarness('a FORBIDDEN refetch is not retried', (h, async) {
      when(() => h.api.getMe()).thenAnswer((_) async {
        throw _operationError('FORBIDDEN');
      });
      h.cubit.start();

      h.lifecycle.foreground.add(null);
      async.elapse(const Duration(minutes: 5));

      verify(() => h.api.getMe()).called(1);
      verifyNever(() => h.auth.adoptUser(any()));
    });

    withHarness('the background suspends the watchdog until the foreground', (
      h,
      async,
    ) {
      h.cubit.start();
      h.connection.add(false);
      async.flushMicrotasks();

      h.lifecycle.background.add(null);
      async.elapse(const Duration(minutes: 10));
      expect(h.expiries, 0);

      h.lifecycle.foreground.add(null);
      async.elapse(const Duration(minutes: 2, seconds: 59));
      expect(h.expiries, 0);
      async.elapse(const Duration(seconds: 1));
      expect(h.expiries, 1);
    });

    withHarness('three requests in flight produce one refetch', (h, async) {
      final pending = Completer<User>();
      when(() => h.api.getMe()).thenAnswer((_) => pending.future);
      h.cubit.start();

      h.refreshRequests
        ..add(null)
        ..add(null)
        ..add(null);
      async.flushMicrotasks();
      verify(() => h.api.getMe()).called(1);

      pending.complete(buildTestUserWithCharacter());
      async.flushMicrotasks();
      h.refreshRequests.add(null);
      async.flushMicrotasks();
      verify(() => h.api.getMe()).called(1);
    });

    withHarness('prolonged degradation expires exactly once', (h, async) {
      h.cubit.start();
      h.connection.add(false);

      async.elapse(const Duration(minutes: 3));
      async.elapse(const Duration(minutes: 30));

      expect(h.expiries, 1);
    });

    withHarness('close during a refetch drops its late result', (h, async) {
      final pending = Completer<User>();
      when(() => h.api.getMe()).thenAnswer((_) => pending.future);
      h.cubit.start();
      h.lifecycle.foreground.add(null);
      async.flushMicrotasks();

      h.cubit.close();
      async.flushMicrotasks();
      pending.complete(buildTestUserWithCharacter());
      async.flushMicrotasks();

      verifyNever(() => h.auth.adoptUser(any()));
      expect(h.lifecycle.hasListeners, isFalse);
      expect(h.refreshRequests.hasListener, isFalse);
      expect(async.pendingTimers, isEmpty);
    });
  });

  blocTest<SessionSyncCubit, SessionSyncState>(
    'emits live after the first adopted event',
    build: () {
      final api = MockKlimmeckGraphQl();
      final auth = MockAuthTokenService();
      final user = buildTestUserWithCharacter();
      when(
        () => api.subscribeToUser(),
      ).thenAnswer((_) => Stream.multi((c) => c.add(user)));
      when(() => auth.adoptUser(any())).thenReturn(true);
      return SessionSyncCubit(
        api: api,
        auth: auth,
        watchdog: SyncWatchdog(onExpired: () async {}),
        connection: const Stream<bool>.empty(),
        lifecycle: FakeLifecycle(),
        userRefreshRequests: const Stream<void>.empty(),
      );
    },
    act: (cubit) => cubit.start(),
    expect: () => [const SessionSyncLive()],
  );
}
