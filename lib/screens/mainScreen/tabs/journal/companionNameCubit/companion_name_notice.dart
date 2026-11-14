import 'package:klimmeck_guide/repository/pet_rename_failure.dart';

/// Riga del rifiuto mostrata nel foglio del nome (D-31), copy provvisoria;
/// nessuna riga per UNAUTHENTICATED.
String? companionNameRefusalLine(PetRenameFailure failure) => switch (failure) {
  PetRenameFailure.nameInvalid =>
    'Il nome non è accettato dalle cronache, scegline un altro',
  PetRenameFailure.notOwned ||
  PetRenameFailure.notFound => 'Questo compagno non è più con te',
  PetRenameFailure.connection => 'Connessione assente, riprova',
  PetRenameFailure.timedOut => 'Il server non ha risposto in tempo, riprova',
  PetRenameFailure.unauthenticated => null,
  PetRenameFailure.badUserInput ||
  PetRenameFailure.declined ||
  PetRenameFailure.unknown => 'Qualcosa è andato storto, riprova',
};
