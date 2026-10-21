import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:klimmeck_guide/repository/services/push/firebase_push_messaging.dart';
import 'package:klimmeck_guide/repository/services/push/flutter_local_notifications_adapter.dart';
import 'package:klimmeck_guide/repository/services/push/local_notifications_startup.dart';
import 'package:klimmeck_guide/repository/services/push/permission_handler_notification_permission.dart';
import 'package:klimmeck_guide/repository/services/push/push_background_handler.dart';
import 'package:klimmeck_guide/repository/services/push/push_services.dart';

const Duration _firebaseInitTimeout = Duration(seconds: 3);

/// Bootstrap del push prima di `runApp` (D-02): solo chiamate locali, nessuna rete
/// (Phase 11 D-33), ciascuna con un tetto di tempo. Qualunque fallimento disabilita il
/// push con un log e il gioco parte invariato.
Future<PushServices> bootstrapPush() async {
  // iOS rinviato (D-03).
  if (!Platform.isAndroid) return const PushServices.disabled();
  const permission = PermissionHandlerNotificationPermission();
  try {
    await Firebase.initializeApp().timeout(_firebaseInitTimeout);
  } on Object catch (error) {
    debugPrint('Push disabled: Firebase unavailable (${error.runtimeType})');
    return const PushServices.disabled(permission: permission);
  }
  try {
    FirebaseMessaging.onBackgroundMessage(firebaseBackgroundMessageHandler);
    final notifications = FlutterLocalNotificationsAdapter();
    if (!await initializeLocalNotifications(notifications)) {
      return const PushServices.disabled(permission: permission);
    }
    return PushServices(
      messaging: FirebasePushMessaging(FirebaseMessaging.instance),
      localNotifications: notifications,
      permission: permission,
      launchIntent: await readLaunchIntent(notifications),
    );
  } on Object catch (error) {
    debugPrint(
      'Push disabled: notifications unavailable (${error.runtimeType})',
    );
    return const PushServices.disabled(permission: permission);
  }
}
