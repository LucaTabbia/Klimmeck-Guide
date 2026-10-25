import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/notification_category.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/settings/notificationCubit/notification_preferences_cubit.dart';

import '../../../../../helpers/auth_fixtures.dart';
import '../../../../../helpers/fakes/in_memory_notification_preferences_store.dart';

NotificationPreferencesState loaded({
  bool travelEnd = true,
  bool streamerLive = true,
  bool questEnd = true,
  bool questCancelled = true,
}) => NotificationPreferencesState(
  enabled: {
    NotificationCategory.travelEnd: travelEnd,
    NotificationCategory.streamerLive: streamerLive,
    NotificationCategory.questEnd: questEnd,
    NotificationCategory.questCancelled: questCancelled,
  },
  isLoaded: true,
);

class _AlwaysFailingWriteStore extends InMemoryNotificationPreferencesStore {
  @override
  Future<void> setEnabled(
    String userId,
    NotificationCategory category, {
    required bool enabled,
  }) async => throw StateError('write failed');
}

void main() {
  late InMemoryNotificationPreferencesStore store;

  NotificationPreferencesCubit buildCubit() =>
      NotificationPreferencesCubit(store, userId: testUserId);

  Future<NotificationPreferencesCubit> loadedCubit() async {
    final cubit = buildCubit();
    await cubit.load();
    return cubit;
  }

  setUp(() => store = InMemoryNotificationPreferencesStore());

  test('starts with every category enabled and not loaded', () {
    final state = buildCubit().state;

    expect(state, const NotificationPreferencesState());
    expect(state.isLoaded, isFalse);
    for (final category in NotificationCategory.values) {
      expect(state.isEnabled(category), isTrue);
    }
  });

  blocTest<NotificationPreferencesCubit, NotificationPreferencesState>(
    'load emits all enabled when nothing is stored',
    build: buildCubit,
    act: (cubit) => cubit.load(),
    expect: () => [loaded()],
  );

  blocTest<NotificationPreferencesCubit, NotificationPreferencesState>(
    'load reads the stored value of this user and ignores other users',
    setUp: () {
      store.values[InMemoryNotificationPreferencesStore.keyOf(
            testUserId,
            NotificationCategory.travelEnd,
          )] =
          false;
      store.values[InMemoryNotificationPreferencesStore.keyOf(
            'other',
            NotificationCategory.questEnd,
          )] =
          false;
    },
    build: buildCubit,
    act: (cubit) => cubit.load(),
    expect: () => [loaded(travelEnd: false)],
  );

  blocTest<NotificationPreferencesCubit, NotificationPreferencesState>(
    'load falls back to the defaults when the store throws',
    setUp: () => store.readFailure = StateError('read failed'),
    build: buildCubit,
    act: (cubit) => cubit.load(),
    expect: () => [loaded()],
  );

  blocTest<NotificationPreferencesCubit, NotificationPreferencesState>(
    'a second load emits nothing',
    build: buildCubit,
    act: (cubit) async {
      await cubit.load();
      await cubit.load();
    },
    expect: () => [loaded()],
  );

  test('toggle before load emits nothing and writes nothing', () async {
    final cubit = buildCubit();

    await cubit.toggle(NotificationCategory.questEnd, enabled: false);

    expect(cubit.state, const NotificationPreferencesState());
    expect(store.writes, 0);
  });

  blocTest<NotificationPreferencesCubit, NotificationPreferencesState>(
    'toggle emits optimistically and persists the value',
    build: buildCubit,
    act: (cubit) async {
      await cubit.load();
      await cubit.toggle(NotificationCategory.questEnd, enabled: false);
    },
    skip: 1,
    expect: () => [loaded(questEnd: false)],
    verify: (_) {
      expect(store.valueOf(testUserId, NotificationCategory.questEnd), isFalse);
      expect(store.writes, 1);
    },
  );

  blocTest<NotificationPreferencesCubit, NotificationPreferencesState>(
    'toggle with the current value emits nothing and writes nothing',
    build: buildCubit,
    act: (cubit) async {
      await cubit.load();
      await cubit.toggle(NotificationCategory.questEnd, enabled: true);
    },
    skip: 1,
    expect: () => <NotificationPreferencesState>[],
    verify: (_) => expect(store.writes, 0),
  );

  blocTest<NotificationPreferencesCubit, NotificationPreferencesState>(
    'a failed write reverts the category without throwing',
    build: buildCubit,
    act: (cubit) async {
      await cubit.load();
      store.failNextWrite = true;
      await cubit.toggle(NotificationCategory.streamerLive, enabled: false);
    },
    skip: 1,
    expect: () => [loaded(streamerLive: false), loaded()],
    verify: (_) => expect(
      store.valueOf(testUserId, NotificationCategory.streamerLive),
      isNull,
    ),
  );

  test('concurrent toggles revert only the failing category', () async {
    final cubit = await loadedCubit();
    store.failNextWrite = true;

    await Future.wait([
      cubit.toggle(NotificationCategory.travelEnd, enabled: false),
      cubit.toggle(NotificationCategory.questEnd, enabled: false),
    ]);

    expect(cubit.state, loaded(questEnd: false));
  });

  test(
    'two quick taps that both fail leave the state equal to the stored value',
    () async {
      store = _AlwaysFailingWriteStore();
      final cubit = await loadedCubit();

      await Future.wait([
        cubit.toggle(NotificationCategory.questEnd, enabled: false),
        cubit.toggle(NotificationCategory.questEnd, enabled: true),
      ]);

      expect(cubit.state, loaded());
      expect(store.valueOf(testUserId, NotificationCategory.questEnd), isNull);
    },
  );

  test(
    'a load completing after close emits nothing and throws nothing',
    () async {
      final gate = Completer<void>();
      store.readGate = gate;
      final cubit = buildCubit();
      final emitted = <NotificationPreferencesState>[];
      cubit.stream.listen(emitted.add);

      final pending = cubit.load();
      await cubit.close();
      gate.complete();
      await pending;

      expect(emitted, isEmpty);
    },
  );
}
