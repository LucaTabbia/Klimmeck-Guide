part of 'notification_preferences_cubit.dart';

class NotificationPreferencesState extends Equatable {
  NotificationPreferencesState({
    Map<NotificationCategory, bool>? enabled,
    this.isLoaded = false,
  }) : enabled = enabled ?? defaults;

  /// IN-07: derivata dall'enum, una nuova categoria nasce già con il default.
  static final Map<NotificationCategory, bool> defaults = Map.unmodifiable({
    for (final category in NotificationCategory.values)
      category: NotificationCategory.defaultEnabled,
  });

  final Map<NotificationCategory, bool> enabled;
  final bool isLoaded;

  bool isEnabled(NotificationCategory category) =>
      enabled[category] ?? NotificationCategory.defaultEnabled;

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
