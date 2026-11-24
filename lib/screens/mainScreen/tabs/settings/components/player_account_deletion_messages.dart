import 'package:klimmeck_guide/repository/player_account_deletion_failure.dart';

/// Copy di dominio per esito, mai testo del server (ui-ux.md).
extension PlayerAccountDeletionFailureMessage on PlayerAccountDeletionFailure {
  String get message => switch (this) {
    PlayerAccountDeletionFailure.twitchUserNotFound =>
      'Nessun utente Twitch con questo nome',
    PlayerAccountDeletionFailure.accountNotFound =>
      'Questo utente non ha un account nella Guida',
    PlayerAccountDeletionFailure.innkeeperProtected =>
      "Non puoi eliminare l'account di un oste",
    PlayerAccountDeletionFailure.twitchUnavailable =>
      'Twitch non risponde, riprova più tardi',
    PlayerAccountDeletionFailure.connection => 'Errore di connessione, riprova',
    PlayerAccountDeletionFailure.unknown =>
      "Impossibile eliminare l'account, riprova",
  };
}
