import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:klimmeck_guide/repository/services/auth/auth_api_exception.dart'
    show unauthenticatedCode;
import 'package:klimmeck_guide/repository/services/graphql/graphql_error_code.dart';
import 'package:klimmeck_guide/repository/spell_equip_failure.dart'
    show badUserInputCode;
import 'package:klimmeck_guide/repository/transaction_failure.dart'
    show petNotOwnedCode;

/// Esiti di dominio del rifiuto di `equipPet`/`unequipPet` (BE Phase 12
/// D-15); la UI li traduce in copy (D-06).
enum PetEquipFailure {
  /// Vista client stantia: nessun banner, rilettura silenziosa (D-06).
  notOwned,

  /// Vista client stantia: nessun banner, rilettura silenziosa (D-06).
  notFound,
  forbidden,
  badUserInput,
  unauthenticated,
  connection,

  /// Nessuna risposta entro il timeout: la richiesta non è annullata, un
  /// cambio riuscito arriva comunque via `characterUpdated`.
  timedOut,

  /// `successful: false` senza codice.
  declined,
  unknown,
}

class PetEquipException implements Exception {
  const PetEquipException(this.failure);

  final PetEquipFailure failure;

  @override
  String toString() => 'PetEquipException(${failure.name})';
}

/// Solo `extensions.code`: il testo dei messaggi del server non viene mai usato.
PetEquipFailure petEquipFailureFrom(OperationException exception) {
  final code = graphQlErrorCode(exception);
  if (code == null && exception.linkException != null) {
    return PetEquipFailure.connection;
  }
  return switch (code) {
    petNotOwnedCode => PetEquipFailure.notOwned,
    notFoundCode => PetEquipFailure.notFound,
    forbiddenCode => PetEquipFailure.forbidden,
    badUserInputCode => PetEquipFailure.badUserInput,
    unauthenticatedCode => PetEquipFailure.unauthenticated,
    _ => PetEquipFailure.unknown,
  };
}
