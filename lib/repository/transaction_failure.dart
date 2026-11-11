import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:klimmeck_guide/repository/character_imprisoned.dart';
import 'package:klimmeck_guide/repository/services/auth/auth_api_exception.dart'
    show unauthenticatedCode;
import 'package:klimmeck_guide/repository/services/graphql/graphql_error_code.dart';

const String shopNotInCityCode = 'SHOP_NOT_IN_CITY';
const String insufficientFundsCode = 'INSUFFICIENT_FUNDS';
const String itemNotOwnedCode = 'ITEM_NOT_OWNED';
const String insufficientItemQuantityCode = 'INSUFFICIENT_ITEM_QUANTITY';
const String invalidQuantityCode = 'INVALID_QUANTITY';
const String itemNotFoundCode = 'ITEM_NOT_FOUND';
const String itemNotTradableCode = 'ITEM_NOT_TRADABLE';
const String transactionTotalMismatchCode = 'TRANSACTION_TOTAL_MISMATCH';
const String itemNotInShopCode = 'ITEM_NOT_IN_SHOP';
const String petAlreadyOwnedCode = 'PET_ALREADY_OWNED';
const String petNotOwnedCode = 'PET_NOT_OWNED';

/// Esiti di dominio del rifiuto di `doTransaction` (BE Phase 9 §2, 09-CONTEXT
/// C8; codici del pool e dei compagni da BE Phase 12 D-19); solo
/// `extensions.code`, mai il testo del server.
enum TransactionFailure {
  shopNotInCity,
  insufficientFunds,
  itemNotOwned,
  insufficientItemQuantity,
  invalidQuantity,
  itemNotFound,
  itemNotTradable,
  totalMismatch,

  /// Fuori dal pool della città, legendary o non vendibile (BE D-19): il pool
  /// va riletto (D-05).
  itemNotInShop,

  /// Compagno già posseduto (BE D-14).
  petAlreadyOwned,

  /// Vendita di un compagno non più posseduto (BE D-14).
  petNotOwned,

  /// Il personaggio è in prigione (quick 261110-cgd).
  imprisoned,
  notFound,
  forbidden,

  /// BAD_USER_INPUT (BE Phase 10): richiesta rifiutata dalla validazione del
  /// server (Phase 12 D-13a).
  badUserInput,
  unauthenticated,
  connection,
  unknown,
}

TransactionFailure transactionFailureFrom(OperationException exception) {
  final code = graphQlErrorCode(exception);
  if (code == null && exception.linkException != null) {
    return TransactionFailure.connection;
  }
  return switch (code) {
    shopNotInCityCode => TransactionFailure.shopNotInCity,
    insufficientFundsCode => TransactionFailure.insufficientFunds,
    itemNotOwnedCode => TransactionFailure.itemNotOwned,
    insufficientItemQuantityCode => TransactionFailure.insufficientItemQuantity,
    invalidQuantityCode => TransactionFailure.invalidQuantity,
    itemNotFoundCode => TransactionFailure.itemNotFound,
    itemNotTradableCode => TransactionFailure.itemNotTradable,
    transactionTotalMismatchCode => TransactionFailure.totalMismatch,
    itemNotInShopCode => TransactionFailure.itemNotInShop,
    petAlreadyOwnedCode => TransactionFailure.petAlreadyOwned,
    petNotOwnedCode => TransactionFailure.petNotOwned,
    characterImprisonedCode => TransactionFailure.imprisoned,
    notFoundCode => TransactionFailure.notFound,
    forbiddenCode => TransactionFailure.forbidden,
    badUserInputCode => TransactionFailure.badUserInput,
    unauthenticatedCode => TransactionFailure.unauthenticated,
    _ => TransactionFailure.unknown,
  };
}
