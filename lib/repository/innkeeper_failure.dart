import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:klimmeck_guide/repository/services/auth/auth_api_exception.dart'
    show unauthenticatedCode;
import 'package:klimmeck_guide/repository/services/graphql/graphql_error_code.dart';
import 'package:klimmeck_guide/repository/travel_failure.dart'
    show questInProgressCode;

const String outcomeOverrideInvalidCode = 'OUTCOME_OVERRIDE_INVALID';
const String outcomeNotParticipantCode = 'OUTCOME_NOT_PARTICIPANT';

/// Esiti di dominio delle azioni del GM (BE 09 §2, BE 08 §2, BE-HARD-08):
/// solo `extensions.code`, mai il testo del server (10-CONTEXT D-14/C2).
enum InnkeeperFailure {
  notFound,

  /// Il personaggio è in quest: il teletrasporto è rifiutato.
  questInProgress,
  overrideInvalid,
  notParticipant,
  forbidden,
  unauthenticated,
  connection,

  /// Nessuna risposta entro il timeout client: la richiesta non è annullata.
  timedOut,

  /// `successful: false` senza codice: un rifiuto del BE, distinto da una
  /// risposta malformata.
  declined,
  malformed,
  unknown,
}

class InnkeeperException implements Exception {
  const InnkeeperException(this.failure);

  final InnkeeperFailure failure;

  @override
  String toString() => 'InnkeeperException(${failure.name})';
}

InnkeeperFailure innkeeperFailureFrom(OperationException exception) {
  final code = graphQlErrorCode(exception);
  if (code == null && exception.linkException != null) {
    return InnkeeperFailure.connection;
  }
  return switch (code) {
    notFoundCode => InnkeeperFailure.notFound,
    questInProgressCode => InnkeeperFailure.questInProgress,
    outcomeOverrideInvalidCode => InnkeeperFailure.overrideInvalid,
    outcomeNotParticipantCode => InnkeeperFailure.notParticipant,
    forbiddenCode => InnkeeperFailure.forbidden,
    unauthenticatedCode => InnkeeperFailure.unauthenticated,
    _ => InnkeeperFailure.unknown,
  };
}
