import 'package:klimmeck_guide/repository/player_account_deletion_failure.dart';
import 'package:klimmeck_guide/utils/failure_lines.dart';

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
    PlayerAccountDeletionFailure.connection => connectionFailureLine,
    PlayerAccountDeletionFailure.unknown => accountDeletionFailedLine,
  };
}
