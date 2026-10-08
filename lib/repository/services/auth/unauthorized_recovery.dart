/// Capacità additiva (D-32) implementata solo dal servizio di sessione reale.
/// Usata da `AuthAuthLink`, `AuthInterceptor` e `WsReconnectPolicy` dopo una risposta
/// non autenticata; il contratto `AuthTokenService` resta invariato.
abstract interface class UnauthorizedRecovery {
  /// Se il token corrente è diverso da [rejectedToken] (già ruotato) lo ritorna;
  /// altrimenti esegue un refresh forzato single-flight. `null` = sessione non
  /// recuperabile, o [rejectedToken] non appartiene alla sessione corrente.
  Future<String?> recoverFromUnauthorized({String? rejectedToken});
}
