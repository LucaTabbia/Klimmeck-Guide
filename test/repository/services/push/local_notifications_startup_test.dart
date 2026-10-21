import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/notification_category.dart';
import 'package:klimmeck_guide/models/notification_intent.dart';
import 'package:klimmeck_guide/repository/services/push/local_notifications_startup.dart';

import '../../../helpers/fakes/recording_local_notifications_port.dart';

void main() {
  final launch = NotificationIntent(
    category: NotificationCategory.travelEnd,
    sentAt: DateTime.utc(2026, 10, 20, 12),
    id: 'travel-a',
  );

  late RecordingLocalNotificationsPort notifications;

  setUp(() => notifications = RecordingLocalNotificationsPort());

  group('initializeLocalNotifications', () {
    test('is ready when the plugin initialises', () async {
      expect(await initializeLocalNotifications(notifications), isTrue);
      expect(notifications.initializeCalls, 1);
    });

    test('is not ready when the plugin fails', () async {
      notifications.initializeFailure = StateError('channel');

      expect(await initializeLocalNotifications(notifications), isFalse);
    });

    test('gives up on a plugin that never answers', () {
      fakeAsync((async) {
        notifications.pendingInitialize = Completer<void>();
        bool? ready;
        initializeLocalNotifications(notifications).then((r) => ready = r);

        async.elapse(localNotificationsStartupTimeout);

        expect(ready, isFalse);
      });
    });
  });

  group('readLaunchIntent', () {
    test('returns the tap that launched the app', () async {
      notifications.launch = launch;

      expect(await readLaunchIntent(notifications), launch);
    });

    test('returns null when the plugin fails', () async {
      notifications.launchFailure = StateError('channel');

      expect(await readLaunchIntent(notifications), isNull);
    });

    test('returns null for a plugin that never answers', () {
      fakeAsync((async) {
        notifications.pendingLaunch = Completer<NotificationIntent?>();
        var resolved = false;
        NotificationIntent? intent = launch;
        readLaunchIntent(notifications).then((value) {
          resolved = true;
          intent = value;
        });

        async.elapse(localNotificationsStartupTimeout);

        expect(resolved, isTrue);
        expect(intent, isNull);
      });
    });
  });
}
