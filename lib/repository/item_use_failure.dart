import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:klimmeck_guide/repository/services/auth/auth_api_exception.dart'
    show unauthenticatedCode;
import 'package:klimmeck_guide/repository/services/graphql/graphql_error_code.dart';
import 'package:klimmeck_guide/repository/transaction_failure.dart'
    show itemNotOwnedCode;
import 'package:klimmeck_guide/repository/travel_failure.dart'
    show awaitingAidCode;

const String itemNotUsableCode = 'ITEM_NOT_USABLE';
const String potionRecoveringCode = 'POTION_RECOVERING';
const String itemNoEffectCode = 'ITEM_NO_EFFECT';

/// Chiave di `extensions` con la fine della ricarica (stringa ISO 8601).
const String recoveryUntilExtension = 'recoveryUntil';

/// Esiti di dominio del rifiuto di `useItem` (BE Phase 18, D-11).
enum ItemUseFailure {
  /// Un'altra pozione è ancora in ricarica.
  potionRecovering,

  /// La pozione non cambierebbe nulla: non è consumata.
  noEffect,
  awaitingAid,
  notOwned,
  notUsable,

  /// BAD_USER_INPUT: richiesta rifiutata dalla validazione del server.
  badUserInput,
  connection,

  /// Nessuna risposta entro il timeout client: la richiesta non è annullata.
  timedOut,
  unauthenticated,
  unknown,
}

class ItemUseException implements Exception {
  const ItemUseException(this.failure, {this.recoveryUntil});

  final ItemUseFailure failure;

  /// Fine della ricarica detta dal server, solo per una ricarica in corso
  /// (D-19); `null` se il server non l'ha mandata leggibile.
  final DateTime? recoveryUntil;

  @override
  String toString() => 'ItemUseException(${failure.name})';
}

/// Solo `extensions.code`: il testo dei messaggi del server non viene mai usato.
ItemUseFailure itemUseFailureFrom(OperationException exception) {
  final code = graphQlErrorCode(exception);
  if (code == null && exception.linkException != null) {
    return ItemUseFailure.connection;
  }
  return switch (code) {
    potionRecoveringCode => ItemUseFailure.potionRecovering,
    itemNoEffectCode => ItemUseFailure.noEffect,
    awaitingAidCode => ItemUseFailure.awaitingAid,
    itemNotOwnedCode => ItemUseFailure.notOwned,
    itemNotUsableCode => ItemUseFailure.notUsable,
    badUserInputCode => ItemUseFailure.badUserInput,
    unauthenticatedCode => ItemUseFailure.unauthenticated,
    _ => ItemUseFailure.unknown,
  };
}

/// Il rifiuto con la data del server quando è una ricarica in corso (D-19).
ItemUseException itemUseExceptionFrom(OperationException exception) {
  final failure = itemUseFailureFrom(exception);
  if (failure != ItemUseFailure.potionRecovering) {
    return ItemUseException(failure);
  }
  final wire = graphQlErrorExtension(exception, recoveryUntilExtension);
  return ItemUseException(
    failure,
    recoveryUntil: wire is String ? DateTime.tryParse(wire)?.toUtc() : null,
  );
}
