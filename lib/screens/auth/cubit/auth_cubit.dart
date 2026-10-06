import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/repository/services/auth/auth_token_service.dart';

/// Stato di sessione di processo (globale, sopra MaterialApp). Unico consumer di
/// `authStateStream` per la UI; `AuthGate` costruisce l'albero da questo stato.
class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this._authTokenService) : super(const AuthBootstrapping());

  final AuthTokenService _authTokenService;
  StreamSubscription<AuthState>? _subscription;

  /// Avvia il bootstrap (D-33): sottoscrive lo stream e poi chiama `initialize()`,
  /// che non blocca il primo frame (il retry di rete prosegue dentro il servizio).
  Future<void> start() async {
    if (_subscription != null) return;
    _subscription = _authTokenService.authStateStream.listen((authState) {
      if (!isClosed) emit(authState);
    });
    await _authTokenService.initialize();
  }

  /// D-18: "Accedi manualmente" durante un cold start lento.
  void showSignIn() {
    if (state is AuthBootstrapping) emit(const AuthUnauthenticated());
  }

  Future<void> logout() => _authTokenService.logout();

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
