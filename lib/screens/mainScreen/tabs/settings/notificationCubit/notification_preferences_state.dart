part of 'notification_preferences_cubit.dart';

class NotificationPreferencesState extends Equatable {
  const NotificationPreferencesState({
    this.enabled = defaults,
    this.isLoaded = false,
  });

  static const Map<NotificationCategory, bool> defaults = {
    NotificationCategory.travelEnd: true,
    NotificationCategory.streamerLive: true,
    NotificationCategory.questEnd: true,
  };

  final Map<NotificationCategory, bool> enabled;
  final bool isLoaded;

  bool isEnabled(NotificationCategory category) => enabled[category] ?? true;

  NotificationPreferencesState withCategory(
    NotificationCategory category, {
    required bool enabled,
  }) => NotificationPreferencesState(
    enabled: Map.unmodifiable({...this.enabled, category: enabled}),
    isLoaded: isLoaded,
  );

  @override
  List<Object> get props => [enabled, isLoaded];
}
