import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/models/notification_category.dart';
import 'package:klimmeck_guide/repository/storage/notification_preferences_store.dart';
import 'package:klimmeck_guide/shared/bloc/safe_emit.dart';

part 'notification_preferences_state.dart';

/// Toggle notifiche del tab Impostazioni: ottimistici, salvati al tap (D-12).
class NotificationPreferencesCubit extends Cubit<NotificationPreferencesState>
    with SafeEmit<NotificationPreferencesState> {
  NotificationPreferencesCubit(this._store, {required String userId})
    : _userId = userId,
      super(const NotificationPreferencesState());

  final NotificationPreferencesStore _store;
  final String _userId;

  Future<void> load() async {
    if (state.isLoaded) return;
    try {
      final stored = await _store.readAll(_userId);
      emit(
        NotificationPreferencesState(
          enabled: Map.unmodifiable({
            ...NotificationPreferencesState.defaults,
            ...stored,
          }),
          isLoaded: true,
        ),
      );
    } catch (error) {
      debugPrint('[NotificationPreferences] read failed: ${error.runtimeType}');
      emit(const NotificationPreferencesState(isLoaded: true));
    }
  }

  /// Un fallimento di scrittura ripristina solo questa categoria: due toggle
  /// ravvicinati non si sovrascrivono. Nessuna UI d'errore (D-12).
  Future<void> toggle(
    NotificationCategory category, {
    required bool enabled,
  }) async {
    if (!state.isLoaded || state.isEnabled(category) == enabled) return;
    emit(state.withCategory(category, enabled: enabled));
    try {
      await _store.setEnabled(_userId, category, enabled: enabled);
    } catch (error) {
      debugPrint(
        '[NotificationPreferences] write failed: ${error.runtimeType}',
      );
      emit(state.withCategory(category, enabled: !enabled));
    }
  }
}
