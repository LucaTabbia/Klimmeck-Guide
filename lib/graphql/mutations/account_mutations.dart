class AccountMutations {
  /// Elimina l'account del chiamante e tutto ciò che gli appartiene (BE Phase 26,
  /// D-20). Rifiutata per l'oste (`INNKEEPER_ACCOUNT_PROTECTED`, D-16).
  static const String deleteMyAccount = r'''
    mutation DeleteMyAccount {
      deleteMyAccount
    }
  ''';

  /// Solo oste: elimina l'account di un giocatore dal nome utente Twitch (D-15).
  static const String deleteAccountByTwitchLogin = r'''
    mutation DeleteAccountByTwitchLogin($twitchLogin: String!) {
      deleteAccountByTwitchLogin(twitchLogin: $twitchLogin) {
        twitchId
      }
    }
  ''';
}
