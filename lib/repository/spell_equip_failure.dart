import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:klimmeck_guide/repository/services/auth/auth_api_exception.dart'
    show unauthenticatedCode;
import 'package:klimmeck_guide/repository/services/graphql/graphql_error_code.dart';

const String spellNotKnownCode = 'SPELL_NOT_KNOWN';
const String spellAlreadyActiveCode = 'SPELL_ALREADY_ACTIVE';
const String maxActiveSpellsReachedCode = 'MAX_ACTIVE_SPELLS_REACHED';
const String spellNotActiveCode = 'SPELL_NOT_ACTIVE';
const String badUserInputCode = 'BAD_USER_INPUT';

/// Esiti di dominio del rifiuto di `equipSpell`/`unequipSpell` (BE Phase 4 §2,
/// invariati dalla 9.1); la UI li traduce in copy (D-17).
enum SpellEquipFailure {
  notKnown,

  /// Vista client stantia: nessun banner, rilettura silenziosa (D-17).
  alreadyActive,
  slotsFull,

  /// Vista client stantia: nessun banner, rilettura silenziosa (D-17).
  notActive,
  notFound,
  forbidden,

  /// Arriva con la BE Phase 10 (validazione input).
  badUserInput,
  unauthenticated,
  connection,

  /// Nessuna risposta entro il timeout: la richiesta non è annullata, un
  /// cambio riuscito comunque arriva via `characterUpdated`.
  timedOut,

  /// `successful: false` senza codice: un rifiuto del BE, distinto da una
  /// risposta malformata (`unknown`).
  declined,
  unknown,
}

class SpellEquipException implements Exception {
  const SpellEquipException(this.failure);

  final SpellEquipFailure failure;

  @override
  String toString() => 'SpellEquipException(${failure.name})';
}

/// Solo `extensions.code`: il testo dei messaggi del server non viene mai usato.
SpellEquipFailure spellEquipFailureFrom(OperationException exception) {
  final code = graphQlErrorCode(exception);
  if (code == null && exception.linkException != null) {
    return SpellEquipFailure.connection;
  }
  return switch (code) {
    spellNotKnownCode => SpellEquipFailure.notKnown,
    spellAlreadyActiveCode => SpellEquipFailure.alreadyActive,
    maxActiveSpellsReachedCode => SpellEquipFailure.slotsFull,
    spellNotActiveCode => SpellEquipFailure.notActive,
    notFoundCode => SpellEquipFailure.notFound,
    forbiddenCode => SpellEquipFailure.forbidden,
    badUserInputCode => SpellEquipFailure.badUserInput,
    unauthenticatedCode => SpellEquipFailure.unauthenticated,
    _ => SpellEquipFailure.unknown,
  };
}
