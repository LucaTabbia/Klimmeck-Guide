/// Le due cancellazioni dell'account (BE Phase 26, D-20). Implementazione
/// GraphQL solo dal gate 25-07; fino ad allora nei test un fake.
/// Lancia OperationException (codici in `extensions.code`) o FormatException.
abstract interface class AccountDeletionApi {
  /// Cancella l'account della sessione corrente; il BE revoca ogni sessione.
  Future<void> deleteMyAccount();

  /// Cancella l'account di un altro giocatore (solo l'oste, D-15).
  Future<void> deleteAccountByTwitchLogin(String twitchLogin);
}
