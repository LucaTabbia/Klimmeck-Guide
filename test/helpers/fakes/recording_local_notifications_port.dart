import 'dart:async';

import 'package:klimmeck_guide/models/notification_intent.dart';
import 'package:klimmeck_guide/models/push_event.dart';
import 'package:klimmeck_guide/repository/services/push/local_notifications_port.dart';

/// [LocalNotificationsPort] che registra `show`/`cancelAll` ed espone i tap al test.
class RecordingLocalNotificationsPort implements LocalNotificationsPort {
  final List<PushEvent> shown = [];
  int initializeCalls = 0;
  int cancelAllCalls = 0;
  NotificationIntent? launch;
  final StreamController<NotificationIntent> tapController =
      StreamController<NotificationIntent>.broadcast();

  @override
  Future<void> initialize() async => initializeCalls++;

  @override
  Future<void> show(PushEvent event) async => shown.add(event);

  @override
  Stream<NotificationIntent> get taps => tapController.stream;

  @override
  Future<NotificationIntent?> launchIntent() async => launch;

  @override
  Future<void> cancelAll() async => cancelAllCalls++;
}
