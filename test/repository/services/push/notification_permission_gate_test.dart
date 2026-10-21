import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/repository/services/push/notification_permission_gate.dart';
import 'package:klimmeck_guide/repository/services/push/notification_permission_port.dart';

import '../../../helpers/fakes/fake_notification_permission_port.dart';

void main() {
  late FakeNotificationPermissionPort permission;
  late NotificationPermissionGate gate;

  void arrange({
    required NotificationPermissionStatus current,
    NotificationPermissionStatus requestResult =
        NotificationPermissionStatus.granted,
  }) {
    permission = FakeNotificationPermissionPort(
      current: current,
      requestResult: requestResult,
    );
    gate = NotificationPermissionGate(permission);
  }

  group('ensureRequested', () {
    test(
      'prompts when the system has not decided and returns the answer',
      () async {
        arrange(current: NotificationPermissionStatus.notDetermined);

        final result = await gate.ensureRequested();

        expect(result, NotificationPermissionStatus.granted);
        expect(permission.requestCalls, 1);
      },
    );

    test('returns a refusal given at the prompt', () async {
      arrange(
        current: NotificationPermissionStatus.notDetermined,
        requestResult: NotificationPermissionStatus.denied,
      );

      final result = await gate.ensureRequested();

      expect(result, NotificationPermissionStatus.denied);
      expect(permission.requestCalls, 1);
    });

    test('never prompts again once the permission is denied', () async {
      arrange(current: NotificationPermissionStatus.denied);

      final result = await gate.ensureRequested();

      expect(result, NotificationPermissionStatus.denied);
      expect(permission.requestCalls, 0);
    });

    test('never prompts when the permission is already granted', () async {
      arrange(current: NotificationPermissionStatus.granted);

      final result = await gate.ensureRequested();

      expect(result, NotificationPermissionStatus.granted);
      expect(permission.requestCalls, 0);
    });

    test('prompts once across sequential calls', () async {
      arrange(current: NotificationPermissionStatus.notDetermined);

      await gate.ensureRequested();
      final second = await gate.ensureRequested();

      expect(second, NotificationPermissionStatus.granted);
      expect(permission.requestCalls, 1);
    });

    test('shares one prompt between concurrent calls', () async {
      arrange(current: NotificationPermissionStatus.notDetermined);

      final results = await Future.wait([
        gate.ensureRequested(),
        gate.ensureRequested(),
      ]);

      expect(results, [
        NotificationPermissionStatus.granted,
        NotificationPermissionStatus.granted,
      ]);
      expect(permission.requestCalls, 1);
    });
  });
}
