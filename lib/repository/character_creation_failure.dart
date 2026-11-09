import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:klimmeck_guide/repository/services/graphql/graphql_error_code.dart';
import 'package:klimmeck_guide/repository/spell_equip_failure.dart'
    show badUserInputCode;

const String characterNameInvalidCode = 'CHARACTER_NAME_INVALID';
const String characterNameTakenCode = 'CHARACTER_NAME_TAKEN';
const String characterAgeOutOfRangeCode = 'CHARACTER_AGE_OUT_OF_RANGE';
const String characterAlreadyExistsCode = 'CHARACTER_ALREADY_EXISTS';
const String startingLocationUnavailableCode = 'STARTING_LOCATION_UNAVAILABLE';
const String imageRejectedCode = 'IMAGE_REJECTED';
const String imageModerationUnavailableCode = 'IMAGE_MODERATION_UNAVAILABLE';

/// Esiti di dominio della creazione personaggio; la UI li traduce in copy italiana.
enum CharacterCreationFailure {
  uploadFailed,

  /// Ritratto rifiutato dalla moderazione (REST 422 `IMAGE_REJECTED`, BE
  /// Phase 10).
  imageRejected,

  /// Moderazione non raggiungibile (REST 503 `IMAGE_MODERATION_UNAVAILABLE`).
  moderationUnavailable,
  nameInvalid,
  nameTaken,
  ageOutOfRange,
  alreadyExists,
  startingLocationUnavailable,
  connection,

  /// BAD_USER_INPUT (BE Phase 10): richiesta rifiutata dalla validazione del
  /// server (Phase 12 D-13a).
  badUserInput,

  /// Personaggio creato ma `adoptUser` rifiutato dalla sessione (D-26).
  handoverRejected,
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
  final code = graphQlErrorCode(exception);
  if (code == null && exception.linkException != null) {
    return CharacterCreationFailure.connection;
  }
  return switch (code) {
    characterNameInvalidCode => CharacterCreationFailure.nameInvalid,
    characterNameTakenCode => CharacterCreationFailure.nameTaken,
    characterAgeOutOfRangeCode => CharacterCreationFailure.ageOutOfRange,
    characterAlreadyExistsCode => CharacterCreationFailure.alreadyExists,
    startingLocationUnavailableCode =>
      CharacterCreationFailure.startingLocationUnavailable,
    badUserInputCode => CharacterCreationFailure.badUserInput,
    _ => CharacterCreationFailure.unknown,
  };
}

/// Esito di un upload del ritratto rifiutato via REST: solo `code` del corpo
/// `{statusCode, code, message, reasons}`, mai il testo del server (D-13b).
CharacterCreationFailure portraitUploadFailureFrom(Object? responseData) {
  final code = responseData is Map ? responseData['code'] : null;
  return switch (code) {
    imageRejectedCode => CharacterCreationFailure.imageRejected,
    imageModerationUnavailableCode =>
      CharacterCreationFailure.moderationUnavailable,
    _ => CharacterCreationFailure.uploadFailed,
  };
}
