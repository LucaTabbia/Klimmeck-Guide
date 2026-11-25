import 'package:klimmeck_guide/repository/character_deletion_failure.dart';
import 'package:klimmeck_guide/utils/failure_lines.dart';

/// Copy di dominio per esito, mai testo del server (ui-ux.md).
extension CharacterDeletionFailureMessage on CharacterDeletionFailure {
  String get message => switch (this) {
    CharacterDeletionFailure.connection => connectionFailureLine,
    CharacterDeletionFailure.handoverRejected =>
      'Personaggio eliminato, ma la sessione non si è aggiornata: esci e rientra',
    CharacterDeletionFailure.notFound ||
    CharacterDeletionFailure.badUserInput ||
    CharacterDeletionFailure.unauthenticated ||
    CharacterDeletionFailure.unknown =>
      'Impossibile eliminare il personaggio, riprova',
  };
}
