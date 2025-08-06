import 'package:flutter/material.dart';

import '../models/user.dart';
import '../screens/mainScreen/main_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/onBoarding/on_boarding_screen.dart';
import '../screens/signIn/sign_in_screen.dart';

Route mainScreenRoute() {
  return PageRouteBuilder(
    transitionDuration: const Duration(milliseconds: 400),
    reverseTransitionDuration: const Duration(milliseconds: 400),
    pageBuilder: (context, animation, secondaryAnimation) => const MainScreen(),
    transitionsBuilder: (context, animation, secondaryAnimation, page) {
      var begin = const Offset(1.0, 0.0);
      var end = Offset.zero;
      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: Curves.linear));

      return SlideTransition(position: animation.drive(tween), child: page);
    },
  );
}

Route onBoardingRoute() {
  return PageRouteBuilder(
    transitionDuration: const Duration(milliseconds: 400),
    reverseTransitionDuration: const Duration(milliseconds: 400),
    pageBuilder: (context, animation, secondaryAnimation) => const OnBoardingScreen(),
    transitionsBuilder: (context, animation, secondaryAnimation, page) {
      var begin = const Offset(1.0, 0.0);
      var end = Offset.zero;
      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: Curves.linear));

      return SlideTransition(position: animation.drive(tween), child: page);
    },
  );
}

Route signInRoute() {
  return PageRouteBuilder(
    transitionDuration: const Duration(milliseconds: 400),
    reverseTransitionDuration: const Duration(milliseconds: 400),
    pageBuilder: (context, animation, secondaryAnimation) => const SignInScreen(),
    transitionsBuilder: (context, animation, secondaryAnimation, page) {
      var begin = const Offset(1.0, 0.0);
      var end = Offset.zero;
      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: Curves.linear));

      return SlideTransition(position: animation.drive(tween), child: page);
    },
  );
}

Route notificationRoute(User user) {
  return PageRouteBuilder(
    transitionDuration: const Duration(milliseconds: 400),
    reverseTransitionDuration: const Duration(milliseconds: 400),
    pageBuilder: (context, animation, secondaryAnimation) => NotificationsScreen(user: user),
  );
}
