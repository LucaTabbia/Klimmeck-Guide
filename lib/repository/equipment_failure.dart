import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:klimmeck_guide/repository/mission_in_progress.dart';
import 'package:klimmeck_guide/repository/services/auth/auth_api_exception.dart'
    show unauthenticatedCode;
import 'package:klimmeck_guide/repository/services/graphql/graphql_error_code.dart';

/// Esiti di dominio del rifiuto di `equipItem`; la UI li traduce in copy
/// (D-30).
enum EquipmentFailure {
  /// Missione in corso (BE Phase 22, D-11).
  missionInProgress,
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

class EquipmentException implements Exception {
  const EquipmentException(this.failure);

  final EquipmentFailure failure;

  @override
  String toString() => 'EquipmentException(${failure.name})';
}

/// Solo `extensions.code`: il testo dei messaggi del server non viene mai usato.
EquipmentFailure equipmentFailureFrom(OperationException exception) {
  final code = graphQlErrorCode(exception);
  if (code == null && exception.linkException != null) {
    return EquipmentFailure.connection;
  }
  return switch (code) {
    missionInProgressCode => EquipmentFailure.missionInProgress,
    notFoundCode => EquipmentFailure.notFound,
    forbiddenCode => EquipmentFailure.forbidden,
    badUserInputCode => EquipmentFailure.badUserInput,
    unauthenticatedCode => EquipmentFailure.unauthenticated,
    _ => EquipmentFailure.unknown,
  };
}
