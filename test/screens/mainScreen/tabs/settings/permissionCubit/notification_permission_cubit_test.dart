import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/repository/services/push/notification_permission_port.dart';
import 'package:klimmeck_guide/repository/services/sync/app_lifecycle_events.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/settings/permissionCubit/notification_permission_cubit.dart';

import '../../../../../helpers/fakes/fake_notification_permission_port.dart';

void main() {
  late FakeNotificationPermissionPort permission;
  late AppLifecycleEventBus lifecycle;

  NotificationPermissionCubit buildCubit() =>
      NotificationPermissionCubit(permission, lifecycle: lifecycle);

  setUp(() {
    permission = FakeNotificationPermissionPort();
    lifecycle = AppLifecycleEventBus();
  });

  tearDown(() {
    expect(permission.requestCalls, 0, reason: 'Settings never prompts');
    return lifecycle.close();
  });

  test('starts unknown, without the disabled hint', () {
    final state = buildCubit().state;

    expect(state, const NotificationPermissionState());
    expect(state.status, isNull);
    expect(state.showsDisabledHint, isFalse);
  });

  blocTest<NotificationPermissionCubit, NotificationPermissionState>(
    'refresh shows the hint for a denied permission',
    setUp: () => permission.current = NotificationPermissionStatus.denied,
    build: buildCubit,
    act: (cubit) => cubit.refresh(),
    expect: () => [
      isA<NotificationPermissionState>()
          .having(
            (s) => s.status,
            'status',
            NotificationPermissionStatus.denied,
          )
          .having((s) => s.showsDisabledHint, 'showsDisabledHint', isTrue),
    ],
  );

  for (final status in [
    NotificationPermissionStatus.notDetermined,
    NotificationPermissionStatus.granted,
  ]) {
    blocTest<NotificationPermissionCubit, NotificationPermissionState>(
      'refresh hides the hint for $status',
      setUp: () => permission.current = status,
      build: buildCubit,
      act: (cubit) => cubit.refresh(),
      expect: () => [NotificationPermissionState(status: status)],
      verify: (cubit) => expect(cubit.state.showsDisabledHint, isFalse),
    );
  }

  blocTest<NotificationPermissionCubit, NotificationPermissionState>(
    're-reads the status when the app returns to the foreground',
    setUp: () => permission.current = NotificationPermissionStatus.denied,
    build: buildCubit,
    act: (cubit) async {
      await cubit.refresh();
      permission.current = NotificationPermissionStatus.granted;
      lifecycle.notifyForegrounded();
    },
    expect: () => const [
      NotificationPermissionState(status: NotificationPermissionStatus.denied),
      NotificationPermissionState(status: NotificationPermissionStatus.granted),
    ],
  );

  blocTest<NotificationPermissionCubit, NotificationPermissionState>(
    'a failed status read emits nothing and does not throw',
    setUp: () => permission.statusFailure = StateError('x'),
    build: buildCubit,
    act: (cubit) => cubit.refresh(),
    expect: () => const <NotificationPermissionState>[],
  );

  test('openSettings opens the app system settings', () async {
    final cubit = buildCubit();

    await cubit.openSettings();

    expect(permission.openSettingsCalls, 1);
    await cubit.close();
  });

  test('stops listening to the foreground once closed', () async {
    final cubit = buildCubit();
    await cubit.close();

    lifecycle.notifyForegrounded();
    await Future<void>.delayed(Duration.zero);

    expect(permission.statusCalls, 0);
  });
}
