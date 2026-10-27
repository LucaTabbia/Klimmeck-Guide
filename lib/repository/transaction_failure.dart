import 'package:graphql_flutter/graphql_flutter.dart';
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

/// Esiti di dominio del rifiuto di `doTransaction` (BE Phase 9 §2, 09-CONTEXT
/// C8); solo `extensions.code`, mai il messaggio.
enum TransactionFailure {
  shopNotInCity,
  insufficientFunds,
  itemNotOwned,
  insufficientItemQuantity,
  invalidQuantity,
  itemNotFound,
  itemNotTradable,
  totalMismatch,
  notFound,
  forbidden,
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
    notFoundCode => TransactionFailure.notFound,
    forbiddenCode => TransactionFailure.forbidden,
    unauthenticatedCode => TransactionFailure.unauthenticated,
    _ => TransactionFailure.unknown,
  };
}
