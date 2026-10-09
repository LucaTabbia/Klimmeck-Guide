import 'package:graphql_flutter/graphql_flutter.dart';

const String characterNameInvalidCode = 'CHARACTER_NAME_INVALID';
const String characterNameTakenCode = 'CHARACTER_NAME_TAKEN';
const String characterAgeOutOfRangeCode = 'CHARACTER_AGE_OUT_OF_RANGE';
const String characterAlreadyExistsCode = 'CHARACTER_ALREADY_EXISTS';
const String startingLocationUnavailableCode = 'STARTING_LOCATION_UNAVAILABLE';

/// Esiti di dominio della creazione personaggio; la UI li traduce in copy italiana.
enum CharacterCreationFailure {
  uploadFailed,
  nameInvalid,
  nameTaken,
  ageOutOfRange,
  alreadyExists,
  startingLocationUnavailable,
  connection,
  unknown,
}

class CharacterCreationException implements Exception {
  const CharacterCreationException(this.failure);

  final CharacterCreationFailure failure;

  @override
  String toString() => 'CharacterCreationException(${failure.name})';
}

/// Legge `extensions.code` sia da `graphqlErrors` (HTTP 200) sia dal
/// `parsedResponse` di un `ServerException` (HTTP 400, es. BAD_USER_INPUT).
/// Il testo dei messaggi del server non viene mai usato.
CharacterCreationFailure characterCreationFailureFrom(
  OperationException exception,
) {
  final link = exception.linkException;
  final errors = [
    ...exception.graphqlErrors,
    if (link is ServerException) ...?link.parsedResponse?.errors,
  ];
  final code = errors
      .map((error) => error.extensions?['code'])
      .whereType<String>()
      .firstOrNull;
  if (code == null && link != null) return CharacterCreationFailure.connection;
  return switch (code) {
    characterNameInvalidCode => CharacterCreationFailure.nameInvalid,
    characterNameTakenCode => CharacterCreationFailure.nameTaken,
    characterAgeOutOfRangeCode => CharacterCreationFailure.ageOutOfRange,
    characterAlreadyExistsCode => CharacterCreationFailure.alreadyExists,
    startingLocationUnavailableCode =>
      CharacterCreationFailure.startingLocationUnavailable,
    _ => CharacterCreationFailure.unknown,
  };
}
