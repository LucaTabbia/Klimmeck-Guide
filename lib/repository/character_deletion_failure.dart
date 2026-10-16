import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:klimmeck_guide/repository/services/auth/auth_api_exception.dart'
    show unauthenticatedCode;
import 'package:klimmeck_guide/repository/services/graphql/graphql_error_code.dart';

const String characterNotFoundCode = 'CHARACTER_NOT_FOUND';

/// Esiti di dominio dell'eliminazione personaggio; la UI li traduce in copy italiana.
enum CharacterDeletionFailure {
  /// Nessun personaggio corrente (doppio tap, stato stantio): si rilegge `me`.
  notFound,
  unauthenticated,
  connection,

  /// Personaggio eliminato ma `adoptUser` rifiutato dalla sessione.
  handoverRejected,
  unknown,
}

class CharacterDeletionException implements Exception {
  const CharacterDeletionException(this.failure);

  final CharacterDeletionFailure failure;

  @override
  String toString() => 'CharacterDeletionException(${failure.name})';
}

/// Solo `extensions.code`: il testo dei messaggi del server non viene mai usato.
CharacterDeletionFailure characterDeletionFailureFrom(
  OperationException exception,
) {
  final code = graphQlErrorCode(exception);
  if (code == null && exception.linkException != null) {
    return CharacterDeletionFailure.connection;
  }
  return switch (code) {
    characterNotFoundCode => CharacterDeletionFailure.notFound,
    unauthenticatedCode => CharacterDeletionFailure.unauthenticated,
    _ => CharacterDeletionFailure.unknown,
  };
}
