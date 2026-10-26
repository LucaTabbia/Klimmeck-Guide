import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:klimmeck_guide/repository/services/auth/auth_api_exception.dart'
    show unauthenticatedCode;
import 'package:klimmeck_guide/repository/services/graphql/graphql_error_code.dart';
import 'package:klimmeck_guide/repository/travel_failure.dart'
    show travelInProgressCode;

const String questSlotBusyCode = 'QUEST_SLOT_BUSY';
const String questFullCode = 'QUEST_FULL';
const String questAlreadyTakenCode = 'QUEST_ALREADY_TAKEN';
const String questTitleMismatchCode = 'QUEST_TITLE_MISMATCH';
const String questNotInCityCode = 'QUEST_NOT_IN_CITY';
const String questNotAcceptableCode = 'QUEST_NOT_ACCEPTABLE';
const String insufficientPointsCode = 'INSUFFICIENT_POINTS';

/// Esiti di dominio del rifiuto di `acceptQuest`; la UI li traduce in copy (D-04).
enum QuestAcceptanceFailure {
  slotBusy,
  full,
  alreadyTaken,
  titleMismatch,
  notInCity,
  notAcceptable,
  insufficientPoints,
  notFound,
  forbidden,

  /// BE Phase 8 D-19.
  travelInProgress,
  unauthenticated,
  connection,

  /// Nessuna risposta entro il timeout client: la richiesta non è annullata,
  /// il BE può ancora accettare la quest e la corsia arriverà via subscription.
  timedOut,
  unknown,
}

class QuestAcceptanceException implements Exception {
  const QuestAcceptanceException(this.failure);

  final QuestAcceptanceFailure failure;

  @override
  String toString() => 'QuestAcceptanceException(${failure.name})';
}

/// Solo `extensions.code`: il testo dei messaggi del server non viene mai usato.
QuestAcceptanceFailure questAcceptanceFailureFrom(
  OperationException exception,
) {
  final code = graphQlErrorCode(exception);
  if (code == null && exception.linkException != null) {
    return QuestAcceptanceFailure.connection;
  }
  return switch (code) {
    questSlotBusyCode => QuestAcceptanceFailure.slotBusy,
    questFullCode => QuestAcceptanceFailure.full,
    questAlreadyTakenCode => QuestAcceptanceFailure.alreadyTaken,
    questTitleMismatchCode => QuestAcceptanceFailure.titleMismatch,
    questNotInCityCode => QuestAcceptanceFailure.notInCity,
    questNotAcceptableCode => QuestAcceptanceFailure.notAcceptable,
    insufficientPointsCode => QuestAcceptanceFailure.insufficientPoints,
    travelInProgressCode => QuestAcceptanceFailure.travelInProgress,
    notFoundCode => QuestAcceptanceFailure.notFound,
    forbiddenCode => QuestAcceptanceFailure.forbidden,
    unauthenticatedCode => QuestAcceptanceFailure.unauthenticated,
    _ => QuestAcceptanceFailure.unknown,
  };
}
