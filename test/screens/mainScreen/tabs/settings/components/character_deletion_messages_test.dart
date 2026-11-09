import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/repository/character_deletion_failure.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/settings/components/character_deletion_messages.dart';

void main() {
  test('badUserInput keeps the deletion generic copy (D-13)', () {
    expect(
      CharacterDeletionFailure.badUserInput.message,
      'Impossibile eliminare il personaggio, riprova',
    );
  });

  test('connection says connection (D-13)', () {
    expect(
      CharacterDeletionFailure.connection.message,
      'Errore di connessione, riprova',
    );
  });
}
