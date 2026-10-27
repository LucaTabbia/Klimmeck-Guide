import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:klimmeck_guide/repository/services/auth/auth_api_exception.dart'
    show unauthenticatedCode;
import 'package:klimmeck_guide/repository/services/graphql/graphql_error_code.dart';

/// Esiti di dominio della lettura/conferma di un risultato (BE Phase 9 §2,
/// BE 9.2): solo `extensions.code`.
enum QuestResultFailure {
  notFound,
  forbidden,
  unauthenticated,
  connection,
  timedOut,
  malformed,
  unknown,
}

class QuestResultException implements Exception {
  const QuestResultException(this.failure);

  final QuestResultFailure failure;

  @override
  String toString() => 'QuestResultException(${failure.name})';
}

/// Solo `extensions.code`: il testo dei messaggi del server non viene mai usato.
QuestResultFailure questResultFailureFrom(OperationException exception) {
  final code = graphQlErrorCode(exception);
  if (code == null && exception.linkException != null) {
    return QuestResultFailure.connection;
  }
  return switch (code) {
    notFoundCode => QuestResultFailure.notFound,
    forbiddenCode => QuestResultFailure.forbidden,
    unauthenticatedCode => QuestResultFailure.unauthenticated,
    _ => QuestResultFailure.unknown,
  };
}
