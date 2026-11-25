import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/repository/account_deletion_failure.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/settings/components/account_deletion_messages.dart';

void main() {
  test('connection says connection', () {
    expect(
      AccountDeletionFailure.connection.message,
      'Errore di connessione, riprova',
    );
  });

  test('innkeeperProtected says the innkeeper cannot do it here (D-16)', () {
    expect(
      AccountDeletionFailure.innkeeperProtected.message,
      "L'oste non può eliminare il proprio account dall'App",
    );
  });

  test('unauthenticated keeps the generic copy', () {
    expect(
      AccountDeletionFailure.unauthenticated.message,
      "Impossibile eliminare l'account, riprova",
    );
  });

  test('unknown keeps the generic copy', () {
    expect(
      AccountDeletionFailure.unknown.message,
      "Impossibile eliminare l'account, riprova",
    );
  });
}
