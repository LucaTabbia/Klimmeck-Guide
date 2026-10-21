import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:klimmeck_guide/config/push_channel.dart';
import 'package:klimmeck_guide/models/notification_intent.dart';
import 'package:klimmeck_guide/models/push_event.dart';
import 'package:klimmeck_guide/repository/services/push/local_notifications_port.dart';

/// Adapter di [LocalNotificationsPort] su flutter_local_notifications 19.3.0.
class FlutterLocalNotificationsAdapter implements LocalNotificationsPort {
  FlutterLocalNotificationsAdapter([FlutterLocalNotificationsPlugin? plugin])
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const InitializationSettings _settings = InitializationSettings(
    android: AndroidInitializationSettings(PushChannel.smallIcon),
  );
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    PushChannel.id,
    PushChannel.name,
    description: PushChannel.description,
    importance: Importance.high,
  );
  static const NotificationDetails _details = NotificationDetails(
    android: AndroidNotificationDetails(
      PushChannel.id,
      PushChannel.name,
      channelDescription: PushChannel.description,
      importance: Importance.high,
      priority: Priority.high,
    ),
  );

  final FlutterLocalNotificationsPlugin _plugin;
  final StreamController<NotificationIntent> _taps =
      StreamController<NotificationIntent>.broadcast();

  /// Isolate principale: canale + tap. Creare il canale non mostra il prompt (target 36).
  @override
  Future<void> initialize() async {
    await _plugin.initialize(
      _settings,
      onDidReceiveNotificationResponse: _onTap,
    );
    await _createChannel();
  }

  /// Isolate in background: solo canale, nessun callback (i tap arrivano all'isolate principale).
  Future<void> initializeWithoutTaps() async {
    await _plugin.initialize(_settings);
    await _createChannel();
  }

  @override
  Future<void> show(PushEvent event) => _plugin.show(
    event.notificationId,
    event.title,
    event.body,
    _details,
    payload: event.intent.toPayload(),
  );

  @override
  Stream<NotificationIntent> get taps => _taps.stream;

  @override
  Future<NotificationIntent?> launchIntent() async {
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details == null || !details.didNotificationLaunchApp) return null;
    return NotificationIntent.tryFromPayload(
      details.notificationResponse?.payload,
    );
  }

  @override
  Future<void> cancelAll() => _plugin.cancelAll();

  Future<void> _createChannel() async => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(_channel);

  void _onTap(NotificationResponse response) {
    final intent = NotificationIntent.tryFromPayload(response.payload);
    if (intent != null && !_taps.isClosed) _taps.add(intent);
  }
}
