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

  /// Se impostati, `initialize`/`launchIntent` restano in attesa o falliscono.
  Completer<void>? pendingInitialize;
  Object? initializeFailure;
  Completer<NotificationIntent?>? pendingLaunch;
  Object? launchFailure;
  final StreamController<NotificationIntent> tapController =
      StreamController<NotificationIntent>.broadcast();

  @override
  Future<void> initialize() async {
    initializeCalls++;
    final failure = initializeFailure;
    if (failure != null) throw failure;
    await pendingInitialize?.future;
  }

  @override
  Future<void> show(PushEvent event) async => shown.add(event);

  @override
  Stream<NotificationIntent> get taps => tapController.stream;

  @override
  Future<NotificationIntent?> launchIntent() async {
    final failure = launchFailure;
    if (failure != null) throw failure;
    final pending = pendingLaunch;
    if (pending != null) return pending.future;
    return launch;
  }

  @override
  Future<void> cancelAll() async => cancelAllCalls++;
}
