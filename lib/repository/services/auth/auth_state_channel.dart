import 'dart:async';

import 'auth_token_service.dart';

/// Broadcast di [AuthState] con replay dell'ultimo stato ai nuovi listener.
/// Condiviso dallo stub di sviluppo e dal servizio di sessione reale.
class AuthStateChannel {
  final StreamController<AuthState> _controller =
      StreamController<AuthState>.broadcast();
  AuthState? _current;

  AuthState? get current => _current;

  Stream<AuthState> get stream => Stream<AuthState>.multi((listener) {
    final cached = _current;
    if (cached != null) {
      listener.add(cached);
    }
    final subscription = _controller.stream.listen(
      listener.add,
      onError: listener.addError,
      onDone: listener.close,
    );
    listener.onCancel = subscription.cancel;
  });

  void emit(AuthState state) {
    if (_controller.isClosed) return;
    _current = state;
    _controller.add(state);
  }

  Future<void> close() => _controller.close();
}
