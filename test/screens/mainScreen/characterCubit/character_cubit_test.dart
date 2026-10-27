import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/character/character.dart';
import 'package:klimmeck_guide/repository/services/graphql/graphql_sync_exceptions.dart';
import 'package:klimmeck_guide/repository/services/sync/app_lifecycle_events.dart';
import 'package:klimmeck_guide/repository/services/sync/user_refresh_requests.dart';
import 'package:klimmeck_guide/screens/mainScreen/characterCubit/character_cubit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/fakes/recording_sync_health.dart';
import '../../../helpers/fixtures/sync_event_fixtures.dart';
import '../../../helpers/mocks.dart';

class _FakeCharacter extends Fake implements Character {}

class FakeLifecycle implements AppLifecycleEvents {
  final StreamController<void> background = StreamController<void>.broadcast();
  final StreamController<void> foreground = StreamController<void>.broadcast();

  @override
  Stream<void> get backgrounded => background.stream;

  @override
  Stream<void> get foregrounded => foreground.stream;

  void notifyForegrounded() => foreground.add(null);
}

Character _characterWithHp(int hp) =>
    Character.fromJson(characterJson(id: 'c1', currentLifePoints: hp));

SubscriptionStreamException _streamError(String code) =>
    SubscriptionStreamException(operation: 'characterUpdated', code: code);

GraphQlAccessDeniedException _accessDenied(String code) =>
    GraphQlAccessDeniedException(operation: 'character', code: code);

class CharacterHarness {
  CharacterHarness() {
    when(() => api.getCharacter('c1')).thenAnswer((_) async => _initial);
    when(() => api.subscribeToCharacter('c1')).thenAnswer((_) {
      final controller = StreamController<Character>();
      streams.add(controller);
      return controller.stream;
    });
    cubit = CharacterCubit(
      api,
      health: health,
      lifecycle: lifecycle,
      userRefresh: refreshBus,
    );
    cubit.stream.listen(states.add);
    refreshBus.requests.listen((_) => refreshRequests++);
  }

  final MockKlimmeckGraphQl api = MockKlimmeckGraphQl();
  final RecordingSyncHealth health = RecordingSyncHealth();
  final FakeLifecycle lifecycle = FakeLifecycle();
  final UserRefreshRequestBus refreshBus = UserRefreshRequestBus();
  final List<StreamController<Character>> streams = [];
  final List<CharacterState> states = [];
  final Character _initial = _characterWithHp(10);
  late final CharacterCubit cubit;
  int refreshRequests = 0;

  StreamController<Character> get latestStream => streams.last;

  int get subscriptions => streams.length;

  void dispose() {
    cubit.close();
    refreshBus.close();
  }
}

void withHarness(
  String description,
  void Function(CharacterHarness h, FakeAsync async) body,
) {
  test(description, () {
    fakeAsync((async) {
      final harness = CharacterHarness();
      body(harness, async);
      harness.dispose();
      async.flushMicrotasks();
    });
  });
}

void _loadAndSettle(CharacterHarness h, FakeAsync async) {
  h.cubit.loadCharacter('c1');
  async.flushMicrotasks();
}

void main() {
  late MockKlimmeckGraphQl api;

  setUp(() => api = MockKlimmeckGraphQl());

  group('CharacterCubit closed by a logout while loading', () {
    CharacterCubit buildCubit() => CharacterCubit(
      api,
      health: RecordingSyncHealth(),
      lifecycle: FakeLifecycle(),
      userRefresh: UserRefreshRequestBus(),
    );

    test('never opens the character subscription afterwards', () async {
      final pendingCharacter = Completer<Character>();
      when(
        () => api.getCharacter('c1'),
      ).thenAnswer((_) => pendingCharacter.future);
      when(
        () => api.subscribeToCharacter(any()),
      ).thenAnswer((_) => const Stream<Character>.empty());
      final cubit = buildCubit();
      final load = cubit.loadCharacter('c1');

      await cubit.close();
      pendingCharacter.complete(_FakeCharacter());

      await expectLater(load, completes);
      verifyNever(() => api.subscribeToCharacter(any()));
    });

    test('an open subscription is cancelled on close', () async {
      final updates = StreamController<Character>();
      when(
        () => api.getCharacter('c1'),
      ).thenAnswer((_) async => _FakeCharacter());
      when(
        () => api.subscribeToCharacter('c1'),
      ).thenAnswer((_) => updates.stream);
      final cubit = buildCubit();
      await cubit.loadCharacter('c1');
      expect(updates.hasListener, isTrue);

      await cubit.close();

      expect(updates.hasListener, isFalse);
      await updates.close();
    });
  });

  group('CharacterCubit cold start', () {
    withHarness('emits Loading then Loaded and opens one subscription', (
      h,
      async,
    ) {
      _loadAndSettle(h, async);

      expect(h.states, [CharacterLoading(), CharacterLoaded(h._initial)]);
      expect(h.subscriptions, 1);
      verify(() => h.api.subscribeToCharacter('c1')).called(1);
    });

    withHarness('a failed first load emits Loading then Error', (h, async) {
      when(() => h.api.getCharacter('c1')).thenThrow(Exception('offline'));

      _loadAndSettle(h, async);

      expect(h.states, [CharacterLoading(), isA<CharacterError>()]);
      expect(h.subscriptions, 0);
      expect(h.refreshRequests, 0);
    });

    withHarness('access denied on the first load raises one user refresh', (
      h,
      async,
    ) {
      when(
        () => h.api.getCharacter('c1'),
      ).thenThrow(_accessDenied('FORBIDDEN'));

      _loadAndSettle(h, async);
      async.flushMicrotasks();

      expect(h.states, [CharacterLoading(), const CharacterUnavailable()]);
      expect(h.refreshRequests, 1);
      expect(h.subscriptions, 0);
    });
  });

  group('CharacterCubit character gone (D-13)', () {
    withHarness('NOT_FOUND on the cold start is quiet and unavailable', (
      h,
      async,
    ) {
      when(
        () => h.api.getCharacter('c1'),
      ).thenThrow(_accessDenied('NOT_FOUND'));

      _loadAndSettle(h, async);

      expect(h.states, [CharacterLoading(), const CharacterUnavailable()]);
      expect(h.refreshRequests, 1);
      expect(h.subscriptions, 0);
    });

    withHarness('resumes after an unavailable cold start do nothing', (
      h,
      async,
    ) {
      when(
        () => h.api.getCharacter('c1'),
      ).thenThrow(_accessDenied('NOT_FOUND'));
      _loadAndSettle(h, async);
      h.states.clear();

      h.lifecycle.notifyForegrounded();
      async.flushMicrotasks();
      h.lifecycle.notifyForegrounded();
      async.flushMicrotasks();
      async.elapse(const Duration(minutes: 10));

      verify(() => h.api.getCharacter('c1')).called(1);
      expect(h.refreshRequests, 1);
      expect(h.states, isEmpty);
    });

    withHarness('a refetch NOT_FOUND keeps Loaded and stops refetching', (
      h,
      async,
    ) {
      _loadAndSettle(h, async);
      h.states.clear();
      when(
        () => h.api.getCharacter('c1'),
      ).thenAnswer((_) async => throw _accessDenied('NOT_FOUND'));

      h.lifecycle.notifyForegrounded();
      async.flushMicrotasks();
      async.elapse(const Duration(minutes: 10));
      h.lifecycle.notifyForegrounded();
      async.flushMicrotasks();
      async.elapse(const Duration(minutes: 10));

      verify(() => h.api.getCharacter('c1')).called(2);
      expect(h.refreshRequests, 1);
      expect(h.states, isEmpty);
      expect(h.cubit.state, CharacterLoaded(h._initial));
    });

    withHarness('a stream NOT_FOUND makes later resumes no-ops', (h, async) {
      _loadAndSettle(h, async);
      h.states.clear();

      h.latestStream.addError(_streamError('NOT_FOUND'));
      async.flushMicrotasks();
      h.lifecycle.notifyForegrounded();
      async.flushMicrotasks();
      async.elapse(const Duration(minutes: 10));

      verify(() => h.api.getCharacter('c1')).called(1);
      expect(h.refreshRequests, 1);
      expect(h.states, isEmpty);
      expect(h.cubit.state, CharacterLoaded(h._initial));
    });
  });

  group('CharacterCubit live events', () {
    withHarness('each event re-emits the whole character (SYNC-07)', (
      h,
      async,
    ) {
      _loadAndSettle(h, async);
      h.states.clear();

      h.latestStream.add(_characterWithHp(7));
      async.flushMicrotasks();
      h.latestStream.add(_characterWithHp(3));
      async.flushMicrotasks();

      expect(h.states, [
        CharacterLoaded(_characterWithHp(7)),
        CharacterLoaded(_characterWithHp(3)),
      ]);
      expect(h.health.calls, contains('healthy:characterStream'));
    });
  });

  group('CharacterCubit stream recovery', () {
    withHarness('an error keeps the state and resubscribes with backoff', (
      h,
      async,
    ) {
      _loadAndSettle(h, async);
      h.states.clear();

      h.latestStream.addError(_streamError('INTERNAL_SERVER_ERROR'));
      async.flushMicrotasks();
      expect(h.health.calls, contains('degraded:characterStream'));
      expect(h.subscriptions, 1);

      async.elapse(const Duration(seconds: 1));
      expect(h.subscriptions, 2);

      h.latestStream.addError(_streamError('INTERNAL_SERVER_ERROR'));
      async.flushMicrotasks();
      async.elapse(const Duration(seconds: 1));
      expect(h.subscriptions, 2);
      async.elapse(const Duration(seconds: 1));
      expect(h.subscriptions, 3);

      expect(h.states, isEmpty);
      expect(h.cubit.state, CharacterLoaded(h._initial));
    });

    withHarness('an event resets the attempt counter', (h, async) {
      _loadAndSettle(h, async);

      h.latestStream.addError(_streamError('INTERNAL_SERVER_ERROR'));
      async.flushMicrotasks();
      async.elapse(const Duration(seconds: 1));
      h.latestStream.addError(_streamError('INTERNAL_SERVER_ERROR'));
      async.flushMicrotasks();
      async.elapse(const Duration(seconds: 2));
      expect(h.subscriptions, 3);

      h.latestStream.add(_characterWithHp(5));
      async.flushMicrotasks();
      h.latestStream.addError(_streamError('INTERNAL_SERVER_ERROR'));
      async.flushMicrotasks();
      async.elapse(const Duration(seconds: 1));

      expect(h.subscriptions, 4);
    });

    withHarness('a closed stream resubscribes silently', (h, async) {
      _loadAndSettle(h, async);
      h.states.clear();

      h.latestStream.close();
      async.flushMicrotasks();
      async.elapse(const Duration(seconds: 1));

      expect(h.subscriptions, 2);
      expect(h.states, isEmpty);
    });

    withHarness('a malformed event resubscribes silently', (h, async) {
      _loadAndSettle(h, async);
      h.states.clear();

      h.latestStream.addError(const FormatException('bad payload'));
      async.flushMicrotasks();
      async.elapse(const Duration(seconds: 1));

      expect(h.subscriptions, 2);
      expect(h.states, isEmpty);
    });

    for (final code in ['FORBIDDEN', 'NOT_FOUND']) {
      withHarness('$code ends the stream with one user refresh request', (
        h,
        async,
      ) {
        _loadAndSettle(h, async);
        h.states.clear();

        h.latestStream.addError(_streamError(code));
        h.latestStream.close();
        async.flushMicrotasks();
        async.elapse(const Duration(minutes: 10));

        verify(() => h.api.subscribeToCharacter('c1')).called(1);
        expect(h.refreshRequests, 1);
        expect(h.health.calls, contains('terminated:characterStream'));
        expect(h.states, isEmpty);
        expect(h.cubit.state, CharacterLoaded(h._initial));
      });
    }

    withHarness('close cancels the stream, the timer and the health source', (
      h,
      async,
    ) {
      _loadAndSettle(h, async);
      h.latestStream.addError(_streamError('INTERNAL_SERVER_ERROR'));
      async.flushMicrotasks();
      expect(async.pendingTimers, isNotEmpty);

      h.cubit.close();
      async.flushMicrotasks();

      expect(async.pendingTimers, isEmpty);
      expect(h.health.calls, contains('released:characterStream'));
      async.elapse(const Duration(minutes: 5));
      expect(h.subscriptions, 1);
    });

    withHarness('close cancels a live stream listener', (h, async) {
      _loadAndSettle(h, async);
      expect(h.latestStream.hasListener, isTrue);

      h.cubit.close();
      async.flushMicrotasks();

      expect(h.latestStream.hasListener, isFalse);
    });
  });

  group('CharacterCubit resume refetch', () {
    withHarness('refetches silently on foreground', (h, async) {
      _loadAndSettle(h, async);
      h.states.clear();
      final refreshed = _characterWithHp(4);
      when(() => h.api.getCharacter('c1')).thenAnswer((_) async => refreshed);

      h.lifecycle.notifyForegrounded();
      async.flushMicrotasks();

      verify(() => h.api.getCharacter('c1')).called(2);
      expect(h.states, [CharacterLoaded(refreshed)]);
      expect(h.states, isNot(contains(isA<CharacterLoading>())));
      expect(h.health.calls, contains('touch'));
    });

    withHarness('discards a refetch overtaken by a live event', (h, async) {
      _loadAndSettle(h, async);
      h.states.clear();
      final pending = Completer<Character>();
      when(() => h.api.getCharacter('c1')).thenAnswer((_) => pending.future);

      h.lifecycle.notifyForegrounded();
      async.flushMicrotasks();
      h.latestStream.add(_characterWithHp(2));
      async.flushMicrotasks();
      pending.complete(_characterWithHp(9));
      async.flushMicrotasks();

      expect(h.states, [CharacterLoaded(_characterWithHp(2))]);
      expect(h.health.calls, contains('touch'));
    });

    withHarness('retries transient refetch failures with backoff', (h, async) {
      _loadAndSettle(h, async);
      h.states.clear();
      final refreshed = _characterWithHp(6);
      var attempts = 0;
      when(() => h.api.getCharacter('c1')).thenAnswer((_) async {
        if (++attempts <= 2) throw Exception('x');
        return refreshed;
      });

      h.lifecycle.notifyForegrounded();
      async.flushMicrotasks();
      expect(h.states, isEmpty);
      async.elapse(const Duration(seconds: 1));
      expect(h.states, isEmpty);
      async.elapse(const Duration(seconds: 2));

      expect(h.states, [CharacterLoaded(refreshed)]);
    });

    withHarness('NOT_FOUND on the refetch raises one refresh, no retry', (
      h,
      async,
    ) {
      _loadAndSettle(h, async);
      h.states.clear();
      when(
        () => h.api.getCharacter('c1'),
      ).thenAnswer((_) async => throw _accessDenied('NOT_FOUND'));

      h.lifecycle.notifyForegrounded();
      async.flushMicrotasks();
      async.elapse(const Duration(minutes: 10));

      verify(() => h.api.getCharacter('c1')).called(2);
      expect(h.refreshRequests, 1);
      expect(h.states, isEmpty);
    });

    withHarness('ignores foreground before the first load completes', (
      h,
      async,
    ) {
      h.lifecycle.notifyForegrounded();
      async.flushMicrotasks();

      verifyNever(() => h.api.getCharacter(any()));
    });

    withHarness('a newer foreground supersedes a retrying refetch', (h, async) {
      _loadAndSettle(h, async);
      h.states.clear();
      final stale = _characterWithHp(1);
      final fresh = _characterWithHp(8);
      var calls = 0;
      when(() => h.api.getCharacter('c1')).thenAnswer((_) async {
        calls++;
        if (calls == 1) throw Exception('x');
        if (calls == 2) return fresh;
        return stale;
      });

      h.lifecycle.notifyForegrounded();
      async.flushMicrotasks();
      h.lifecycle.notifyForegrounded();
      async.flushMicrotasks();
      async.elapse(const Duration(minutes: 1));

      expect(h.states, [CharacterLoaded(fresh)]);
    });

    withHarness('close while a refetch waits stops everything', (h, async) {
      _loadAndSettle(h, async);
      when(() => h.api.getCharacter('c1')).thenThrow(Exception('x'));
      h.lifecycle.notifyForegrounded();
      async.flushMicrotasks();
      clearInteractions(h.api);

      h.cubit.close();
      async.flushMicrotasks();
      async.elapse(const Duration(minutes: 5));

      verifyNever(() => h.api.getCharacter(any()));
      expect(async.pendingTimers, isEmpty);
      expect(h.lifecycle.foreground.hasListener, isFalse);
    });
  });
}
