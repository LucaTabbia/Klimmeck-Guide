import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/repository/services/auth/auth_token_service.dart';
import 'package:klimmeck_guide/screens/auth/cubit/auth_cubit.dart';
import 'package:klimmeck_guide/screens/innkeeper/innkeeper_access.dart';
import 'package:klimmeck_guide/screens/innkeeper/innkeeper_panel_route.dart';
import 'package:klimmeck_guide/screens/mainScreen/components/notification_intent_landing.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/map/teleportModeCubit/teleport_mode_cubit.dart';

/// Atterraggio della modalità teletrasporto (10-CONTEXT D-15/D-17): chiude le
/// route radice (il pannello) e salta alla Mappa; al successo riapre il
/// pannello; un ruolo perso annulla. Come `NotificationIntentLanding`, montato
/// solo dove esiste il PageView.
class TeleportModeLanding extends StatelessWidget {
  const TeleportModeLanding({
    super.key,
    required this.pageController,
    required this.child,
  });

  final PageController pageController;
  final Widget child;

  @override
  Widget build(BuildContext context) => MultiBlocListener(
    listeners: [
      BlocListener<TeleportModeCubit, TeleportModeState>(
        listenWhen: (previous, current) =>
            previous is! TeleportActive && current is TeleportActive,
        listener: (context, _) => _landOnMap(context),
      ),
      BlocListener<TeleportModeCubit, TeleportModeState>(
        listenWhen: (previous, current) =>
            previous is! TeleportSucceeded && current is TeleportSucceeded,
        listener: (context, _) => _reopenPanel(context),
      ),
      BlocListener<AuthCubit, AuthState>(
        listenWhen: (previous, current) =>
            isInnkeeperSession(previous) && !isInnkeeperSession(current),
        listener: (context, _) => context.read<TeleportModeCubit>().cancel(),
      ),
    ],
    child: child,
  );

  void _landOnMap(BuildContext context) {
    if (!pageController.hasClients) return;
    Navigator.of(
      context,
      rootNavigator: true,
    ).popUntil((route) => route.isFirst);
    pageController.jumpToPage(NotificationIntentLanding.worldMapPageIndex);
  }

  /// Prima il riconoscimento, poi la route: un solo pannello per successo.
  void _reopenPanel(BuildContext context) {
    context.read<TeleportModeCubit>().acknowledgeSuccess();
    unawaited(openInnkeeperPanel(context));
  }
}
