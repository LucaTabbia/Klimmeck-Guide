import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/models/user.dart';
import 'package:klimmeck_guide/repository/services/auth/auth_token_service.dart';
import 'package:klimmeck_guide/repository/services/push/push_session_cleanup.dart';

/// Stato di sessione di processo (globale, sopra MaterialApp). Unico consumer di
/// `authStateStream` per la UI; `AuthGate` costruisce l'albero da questo stato.
class AuthCubit extends Cubit<AuthState> {
  AuthCubit(
    this._authTokenService, {
    PushSessionCleanup pushCleanup = const NoPushSessionCleanup(),
  }) : _pushCleanup = pushCleanup,
       super(const AuthBootstrapping());

  /// Tetto all'attesa della rimozione del device push: il logout non si blocca mai (D-08).
  static const Duration pushUnregisterTimeout = Duration(seconds: 2);

  final AuthTokenService _authTokenService;
  final PushSessionCleanup _pushCleanup;
  StreamSubscription<AuthState>? _subscription;

  /// Avvia il bootstrap (D-33): sottoscrive lo stream e poi chiama `initialize()`,
  /// che non blocca il primo frame (il retry di rete prosegue dentro il servizio).
  /// Un `initialize()` fallito non lascia il cold start fermo sullo splash:
  /// l'errore va al `BlocObserver` e, se ancora in bootstrap, si va al sign-in.
  Future<void> start() async {
    if (_subscription != null) return;
    _subscription = _authTokenService.authStateStream.listen((authState) {
      if (!isClosed) emit(authState);
    });
    try {
      await _authTokenService.initialize();
    } catch (error, stackTrace) {
      if (isClosed) return;
      addError(error, stackTrace);
      showSignIn();
    }
  }

  /// D-18: "Accedi manualmente" durante un cold start lento.
  void showSignIn() {
    if (state is AuthBootstrapping) emit(const AuthUnauthenticated());
  }

  /// D-02: la sessione adotta lo User restituito da createCharacter. `false`
  /// se la sessione lo rifiuta (D-26): chi chiama deve sbloccare la scheda.
  bool adoptUser(User user) => _authTokenService.adoptUser(user);

  /// D-08: prima la rimozione del device push (best-effort, al massimo 2 s), poi il logout
  /// del backend, che richiede ancora il bearer. `confirmLogout` e "Esci" della creazione
  /// passano tutti di qui.
  Future<void> logout() async {
    await _unregisterPushDevice();
    await _authTokenService.logout();
  }

  Future<void> _unregisterPushDevice() async {
    try {
      await _pushCleanup.unregister().timeout(pushUnregisterTimeout);
    } on Object catch (error) {
      debugPrint('Push unregister skipped (${error.runtimeType})');
    }
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
