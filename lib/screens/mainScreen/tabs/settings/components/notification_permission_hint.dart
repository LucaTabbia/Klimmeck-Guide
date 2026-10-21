import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/settings/permissionCubit/notification_permission_cubit.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';

/// Riga sotto i toggle quando il permesso di sistema è negato (D-10): nessun prompt,
/// solo un rinvio alle impostazioni dell'app. Niente per "mai chiesto" o concesso.
class NotificationPermissionHint extends StatelessWidget {
  const NotificationPermissionHint({super.key});

  static const String message = 'Le notifiche di sistema sono disattivate';
  static const String actionLabel = 'Attiva';

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<
      NotificationPermissionCubit,
      NotificationPermissionState
    >(
      buildWhen: (previous, current) =>
          previous.showsDisabledHint != current.showsDisabledHint,
      builder: (context, state) {
        if (!state.showsDisabledHint) return const SizedBox.shrink();
        final theme = KlimmeckGuideTheme.instance;
        return Padding(
          key: const ValueKey('notification-permission-hint'),
          padding: const EdgeInsets.only(top: KlimmeckGuideTheme.spacingSm),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  message,
                  style: theme.bodyMedium.copyWith(
                    color: KlimmeckGuideTheme.darkWood,
                  ),
                ),
              ),
              TextButton(
                onPressed: context
                    .read<NotificationPermissionCubit>()
                    .openSettings,
                child: Text(
                  actionLabel,
                  style: theme.bodyMedium.copyWith(
                    color: KlimmeckGuideTheme.darkBronze,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
