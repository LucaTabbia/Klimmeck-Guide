import 'auth_token_service.dart';

/// Capability additiva dei servizi di sessione, come `UnauthorizedRecovery`
/// (Phase 11 D-32): non cambia il contratto di [AuthTokenService].
///
/// Eccezione deliberata e stretta a Phase 11 D-09 ("i fallimenti transitori
/// non fanno mai logout"): la usa solo il watchdog della sync (Phase 3 D-15).
abstract interface class SessionTerminator {
  /// Teardown locale come una revoca, con il motivo dato. No-op se la sessione
  /// non è autenticata o se un logout è già in corso.
  Future<void> terminateSession(UnauthenticatedReason reason);
}
