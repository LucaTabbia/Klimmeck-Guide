import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/models/notification_intent.dart';
import 'package:klimmeck_guide/repository/services/auth/auth_token_service.dart';
import 'package:klimmeck_guide/repository/services/push/notification_intent_sink.dart';

part 'notification_intent_state.dart';

/// Tap in attesa di essere consumato da MainScreen (D-15). Vive sopra AuthGate:
/// sopravvive a splash e sign-in (tap da killed), si svuota a fine sessione e
/// sulla pagina di creazione.
class NotificationIntentCubit extends Cubit<NotificationIntentState>
    implements NotificationIntentSink {
  NotificationIntentCubit(Stream<AuthState> authStates)
    : super(const NotificationIntentState()) {
    _authSubscription = authStates.listen(_onAuthState);
  }

  late final StreamSubscription<AuthState> _authSubscription;
  AuthState? _lastAuthState;

  @override
  void offer(NotificationIntent intent) {
    if (_isOnCreationPage) return;
    emit(NotificationIntentState(pending: intent));
  }

  /// Restituisce e cancella il tap in attesa.
  NotificationIntent? consume() {
    final pending = state.pending;
    if (pending != null) emit(const NotificationIntentState());
    return pending;
  }

  void _onAuthState(AuthState next) {
    final previous = _lastAuthState;
    _lastAuthState = next;
    final endedSession =
        next is AuthUnauthenticated && previous is AuthAuthenticated;
    if (endedSession || _isOnCreationPage) _clear();
  }

  bool get _isOnCreationPage => switch (_lastAuthState) {
    AuthAuthenticated(:final user) => user.currentCharacter == null,
    _ => false,
  };

  void _clear() {
    if (state.pending != null && !isClosed) {
      emit(const NotificationIntentState());
    }
  }

  @override
  Future<void> close() async {
    await _authSubscription.cancel();
    return super.close();
  }
}
