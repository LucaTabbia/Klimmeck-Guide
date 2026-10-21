import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/models/notification_category.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/settings/components/notification_permission_hint.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/settings/components/settings_section.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/settings/notificationCubit/notification_preferences_cubit.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';

/// Tre switch per categoria di notifica, inerti finché le preferenze non sono caricate,
/// e sotto la riga del permesso di sistema negato (Phase 5 D-10).
class NotificationPreferencesSection extends StatelessWidget {
  const NotificationPreferencesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<
      NotificationPreferencesCubit,
      NotificationPreferencesState
    >(
      builder: (context, state) => SettingsSection(
        title: 'Notifiche',
        children: [
          for (final category in NotificationCategory.values)
            SwitchListTile(
              key: ValueKey('notification-switch-${category.storageKey}'),
              contentPadding: EdgeInsets.zero,
              title: Text(
                _labelOf(category),
                style: KlimmeckGuideTheme.instance.bodyMedium,
              ),
              value: state.isEnabled(category),
              onChanged: state.isLoaded
                  ? (value) => context
                        .read<NotificationPreferencesCubit>()
                        .toggle(category, enabled: value)
                  : null,
            ),
          const NotificationPermissionHint(),
        ],
      ),
    );
  }

  static String _labelOf(NotificationCategory category) => switch (category) {
    NotificationCategory.travelEnd => 'Fine viaggio',
    NotificationCategory.streamerLive => 'Streamer in live',
    NotificationCategory.questEnd => 'Fine quest',
  };
}
