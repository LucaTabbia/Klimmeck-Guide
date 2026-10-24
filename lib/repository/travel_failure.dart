import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:klimmeck_guide/repository/services/auth/auth_api_exception.dart'
    show unauthenticatedCode;
import 'package:klimmeck_guide/repository/services/graphql/graphql_error_code.dart';

const String travelInProgressCode = 'TRAVEL_IN_PROGRESS';
const String travelSameLocationCode = 'TRAVEL_SAME_LOCATION';
const String travelDestinationNotAllowedCode = 'TRAVEL_DESTINATION_NOT_ALLOWED';
const String travelNoPathCode = 'TRAVEL_NO_PATH';
const String questInProgressCode = 'QUEST_IN_PROGRESS';

/// Esiti di dominio del rifiuto di `travelPreview`/`startTravel` (BE Phase 8 §2);
/// la UI li traduce in copy (07-CONTEXT D-14).
enum TravelFailure {
  inProgress,
  sameLocation,

  /// Difetto di dati (meta non città): solo banner, il BE logga un WARN per il GM.
  destinationNotAllowed,

  /// Difetto di dati stradali: solo banner, il BE logga un WARN per il GM.
  noPath,
  questInProgress,
  notFound,
  forbidden,
  unauthenticated,
  connection,

  /// Nessuna risposta entro il timeout client: la richiesta non è annullata,
  /// un viaggio partito comunque arriva via `characterUpdated`.
  timedOut,
  unknown,
}

class TravelException implements Exception {
  const TravelException(this.failure);

  final TravelFailure failure;

  @override
  String toString() => 'TravelException(${failure.name})';
}

/// Solo `extensions.code`: il testo dei messaggi del server non viene mai usato.
TravelFailure travelFailureFrom(OperationException exception) {
  final code = graphQlErrorCode(exception);
  if (code == null && exception.linkException != null) {
    return TravelFailure.connection;
  }
  return switch (code) {
    travelInProgressCode => TravelFailure.inProgress,
    travelSameLocationCode => TravelFailure.sameLocation,
    travelDestinationNotAllowedCode => TravelFailure.destinationNotAllowed,
    travelNoPathCode => TravelFailure.noPath,
    questInProgressCode => TravelFailure.questInProgress,
    notFoundCode => TravelFailure.notFound,
    forbiddenCode => TravelFailure.forbidden,
    unauthenticatedCode => TravelFailure.unauthenticated,
    _ => TravelFailure.unknown,
  };
}
