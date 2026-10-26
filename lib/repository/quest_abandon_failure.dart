import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:klimmeck_guide/repository/services/auth/auth_api_exception.dart'
    show unauthenticatedCode;
import 'package:klimmeck_guide/repository/services/graphql/graphql_error_code.dart';

const String questNotWaitingCode = 'QUEST_NOT_WAITING';

/// Esiti di dominio del rifiuto di `abandonQuest` (BE Phase 9, 09-19).
enum QuestAbandonFailure {
  /// La quest è già partita (o il personaggio non è ancora sul marker).
  notWaiting,
  notFound,
  forbidden,
  unauthenticated,
  connection,

  /// Nessuna risposta entro il timeout client: la richiesta non è annullata.
  timedOut,
  unknown,
}

class QuestAbandonException implements Exception {
  const QuestAbandonException(this.failure);

  final QuestAbandonFailure failure;

  @override
  String toString() => 'QuestAbandonException(${failure.name})';
}

/// Solo `extensions.code`: il testo dei messaggi del server non viene mai usato.
QuestAbandonFailure questAbandonFailureFrom(OperationException exception) {
  final code = graphQlErrorCode(exception);
  if (code == null && exception.linkException != null) {
    return QuestAbandonFailure.connection;
  }
  return switch (code) {
    questNotWaitingCode => QuestAbandonFailure.notWaiting,
    notFoundCode => QuestAbandonFailure.notFound,
    forbiddenCode => QuestAbandonFailure.forbidden,
    unauthenticatedCode => QuestAbandonFailure.unauthenticated,
    _ => QuestAbandonFailure.unknown,
  };
}
