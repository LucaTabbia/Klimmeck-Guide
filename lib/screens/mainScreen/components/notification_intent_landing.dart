import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/models/notification_category.dart';
import 'package:klimmeck_guide/screens/auth/notificationIntentCubit/notification_intent_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/components/notification_popup_registry.dart';

/// Consuma il tap in attesa (D-15): chiude fogli e dialog sul Navigator radice,
/// salta al tab Mappa e apre l'eventuale popup del tipo. Montato solo dove
/// esiste il PageView (Pitfall 14).
class NotificationIntentLanding extends StatefulWidget {
  const NotificationIntentLanding({
    super.key,
    required this.pageController,
    required this.child,
    this.popups = defaultNotificationPopups,
  });

  /// Indice di WorldMap in `MainScreen._buildPages`.
  static const int worldMapPageIndex = 0;

  final PageController pageController;
  final Widget child;
  final Map<NotificationCategory, NotificationPopup> popups;

  @override
  State<NotificationIntentLanding> createState() =>
      _NotificationIntentLandingState();
}

class _NotificationIntentLandingState extends State<NotificationIntentLanding> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _consumePendingIntent(),
    );
  }

  @override
  Widget build(BuildContext context) =>
      BlocListener<NotificationIntentCubit, NotificationIntentState>(
        listenWhen: (previous, current) =>
            current.pending != null && previous.pending != current.pending,
        listener: (_, _) => _consumePendingIntent(),
        child: widget.child,
      );

  void _consumePendingIntent() {
    if (!mounted || !widget.pageController.hasClients) return;
    final intent = context.read<NotificationIntentCubit>().consume();
    if (intent == null) return;
    Navigator.of(
      context,
      rootNavigator: true,
    ).popUntil((route) => route.isFirst);
    widget.pageController.jumpToPage(
      NotificationIntentLanding.worldMapPageIndex,
    );
    widget.popups[intent.category]?.call(context, intent);
  }
}
