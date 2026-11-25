import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/repository/player_account_deletion_failure.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/settings/components/player_account_deletion_messages.dart';

void main() {
  test('twitchUserNotFound says no Twitch user has that name (D-15)', () {
    expect(
      PlayerAccountDeletionFailure.twitchUserNotFound.message,
      'Nessun utente Twitch con questo nome',
    );
  });

  test('accountNotFound says the user has no account (D-15)', () {
    expect(
      PlayerAccountDeletionFailure.accountNotFound.message,
      'Questo utente non ha un account nella Guida',
    );
  });

  test('innkeeperProtected says an innkeeper cannot be deleted (D-16)', () {
    expect(
      PlayerAccountDeletionFailure.innkeeperProtected.message,
      "Non puoi eliminare l'account di un oste",
    );
  });

  test('twitchUnavailable says Twitch does not answer (D-15)', () {
    expect(
      PlayerAccountDeletionFailure.twitchUnavailable.message,
      'Twitch non risponde, riprova più tardi',
    );
  });

  test('connection says connection', () {
    expect(
      PlayerAccountDeletionFailure.connection.message,
      'Errore di connessione, riprova',
    );
  });

  test('unknown keeps the generic copy', () {
    expect(
      PlayerAccountDeletionFailure.unknown.message,
      "Impossibile eliminare l'account, riprova",
    );
  });
}
