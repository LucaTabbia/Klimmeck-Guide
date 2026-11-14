import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:klimmeck_guide/repository/character_creation_failure.dart'
    show characterNameInvalidCode;
import 'package:klimmeck_guide/repository/services/auth/auth_api_exception.dart'
    show unauthenticatedCode;
import 'package:klimmeck_guide/repository/services/graphql/graphql_error_code.dart';
import 'package:klimmeck_guide/repository/transaction_failure.dart'
    show petNotOwnedCode;

/// Nome rifiutato dalle regole di forma del backend (BE Phase 23, D-31).
const String petNameInvalidCode = 'PET_NAME_INVALID';

/// Esiti di dominio del rifiuto di `renamePet` (D-19, D-31). Il nome non è
/// bloccato da una missione in corso: `MISSION_IN_PROGRESS` non è atteso.
enum PetRenameFailure {
  nameInvalid,

  /// Il compagno non è più del personaggio (vista stantia).
  notOwned,
  notFound,
  badUserInput,
  unauthenticated,
  connection,

  /// Nessuna risposta entro il timeout: un nome salvato arriva comunque via
  /// `characterUpdated`.
  timedOut,

  /// `successful: false` senza codice.
  declined,
  unknown,
}

class PetRenameException implements Exception {
  const PetRenameException(this.failure);

  final PetRenameFailure failure;

  @override
  String toString() => 'PetRenameException(${failure.name})';
}

/// Solo `extensions.code`: il testo dei messaggi del server non viene mai
/// usato. Il codice del nome del personaggio vale come difesa (ricerca F-5).
PetRenameFailure petRenameFailureFrom(OperationException exception) {
  final code = graphQlErrorCode(exception);
  if (code == null && exception.linkException != null) {
    return PetRenameFailure.connection;
  }
  return switch (code) {
    petNameInvalidCode => PetRenameFailure.nameInvalid,
    characterNameInvalidCode => PetRenameFailure.nameInvalid,
    petNotOwnedCode => PetRenameFailure.notOwned,
    notFoundCode => PetRenameFailure.notFound,
    badUserInputCode => PetRenameFailure.badUserInput,
    unauthenticatedCode => PetRenameFailure.unauthenticated,
    _ => PetRenameFailure.unknown,
  };
}
