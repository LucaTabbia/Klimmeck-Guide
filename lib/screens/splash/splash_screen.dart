import 'dart:async';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_svg/svg.dart';
import 'package:klimmeck_guide/repository/storage/storage_manager.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../main.dart';
import '../../routes/routes.dart';
import '../../utils/notification.dart';

Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  //await Firebase.initializeApp();
}

const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'high_importance_channel', // id
  'High Importance Notifications', // title
  description: 'This channel is used for important notifications.',
  // description
  importance: Importance.high,
);
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool onNotificationTrigger = false;

  @override
  void initState() {
    goToPage();
    //getConfigurations();
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(AssetImage('assets/images/worldMap.png'), context);
  }

  Future<void> getConfigurations() async {
    final status = await Permission.notification.status;
    if (status.isDenied || status.isPermanentlyDenied) {
      await Permission.notification.request();
    }
    await firebaseConfiguration();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KlimmeckGuideTheme.deepNight,
      body: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          SizedBox(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            child: Center(
              child: SvgPicture.asset(
                'assets/icons/svg/tavernSign.svg',
                width: MediaQuery.of(context).size.width * 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> goToPage() async {
    Future.delayed(const Duration(milliseconds: 1000), () {
      navigatorKey.currentState?.pushReplacement(mainScreenRoute());
    });
    /*var showOnBoarding = await KGStorageManager.getShowOnBoarding();
    Timer(const Duration(seconds: 3), () async {
      if (showOnBoarding == null || showOnBoarding == true) {
        Navigator.of(context).pushReplacement(onBoardingRoute());
      } else {
        bool alreadyLogged = await KGStorageManager.checkUserLogged();
        User? userLogged = await KGStorageManager.getLoggedUser();
        if (alreadyLogged && userLogged != null) {
          if (mounted) {
            var jsonString = await KGStorageManager.getToken();
            if (jsonString != '') {
              navigatorKey.currentContext
                  ?.read<SplashCubit>()
                  .initializeLoggedUser();
              navigatorKey.currentState?.pushReplacement(mainScreenRoute());
            } else {
              navigatorKey.currentState?.pushReplacement(signInRoute());
            }
          }
        } else {
          if (mounted) {
            Navigator.of(context).pushReplacement(signInRoute());
          }
        }
      }
    })*/
  }

  Future<void> firebaseConfiguration() async {
    var initializationSettingsAndroid = const AndroidInitializationSettings(
      '@drawable/lucy_icona_app',
    );

    var initializationSettingsIOs = const DarwinInitializationSettings();

    var initSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOs,
    );

    var isInitialized = await flutterLocalNotificationsPlugin.initialize(initSettings);
    if (isInitialized == true) {
      FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
        AndroidNotification? android = message.notification?.android;
        var test = <dynamic, dynamic>{};
        final notification = LocalNotification('notification', test);
        NotificationsBloc.instance.newNotification(notification);
        if (android != null) {
          showNotification(message);
        } else {
          if (mounted) {
            setState(() {
              onNotificationTrigger = !onNotificationTrigger;
              if (onNotificationTrigger) {
                showNotification(message);
              }
            });
          }
        }
      });

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
        onSelectNotification(jsonEncode(message.data));
      });

      FirebaseMessaging.instance.getInitialMessage().then(
        (RemoteMessage? message) => {
          if (message == null) {goToPage()} else {onSelectNotification(jsonEncode(message.data))},
        },
      );

      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
      await getFirebaseToken();
    }
    goToPage();
  }

  Future<void> getFirebaseToken() async {
    final status = await Permission.notification.status;
    if (status.isDenied || status.isPermanentlyDenied) {
      Permission.notification.request();
    } else if (status.isGranted) {
      try {
        String? token = await FirebaseMessaging.instance.getToken();
        if (token != null && token != '') {
          await KGStorageManager.saveFirebaseToken(token);
          FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
            await KGStorageManager.saveFirebaseToken(token);
          });
        }
      } catch (e) {
        throw Exception(e);
      }
    }
  }

  Future<void> onSelectNotification(String? payload) async {
    if (payload != null) {}
  }

  void showNotification(RemoteMessage message) async {
    var notificationsChannel = AndroidNotificationDetails(
      channel.id,
      channel.name,
      channelDescription: channel.description,
      importance: Importance.max,
      priority: Priority.high,
    );
    var iOSPlatformChannelSpecifics = const DarwinNotificationDetails();
    var platformChannelSpecifics = NotificationDetails(
      android: notificationsChannel,
      iOS: iOSPlatformChannelSpecifics,
    );
    String title = message.data['title'] ?? message.notification?.title ?? '';
    String body =
        message.data['message'] ?? message.data['body'] ?? message.notification?.body ?? '';
    await flutterLocalNotificationsPlugin.show(
      message.messageId.hashCode,
      title,
      body,
      platformChannelSpecifics,
      payload: jsonEncode(message.data),
    );
    if (!mounted) return;
  }
}
