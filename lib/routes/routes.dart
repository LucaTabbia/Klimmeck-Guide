import 'package:flutter/material.dart';

const Duration _defaultTransitionDuration = Duration(milliseconds: 400);

Route<T> createSlideRoute<T>({
  required Widget page,
  Duration transitionDuration = _defaultTransitionDuration,
}) {
  return PageRouteBuilder<T>(
    transitionDuration: transitionDuration,
    reverseTransitionDuration: transitionDuration,
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(1.0, 0.0);
      const end = Offset.zero;
      final tween = Tween(begin: begin, end: end).chain(
        CurveTween(curve: Curves.easeInOut),
      );

      return SlideTransition(
        position: animation.drive(tween),
        child: child,
      );
    },
  );
}

Route<T> createFadeRoute<T>({
  required Widget page,
  Duration transitionDuration = _defaultTransitionDuration,
}) {
  return PageRouteBuilder<T>(
    transitionDuration: transitionDuration,
    reverseTransitionDuration: transitionDuration,
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: animation,
        child: child,
      );
    },
  );
}
