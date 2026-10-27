import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:klimmeck_guide/repository/transaction_failure.dart';

OperationException _withCode(String code) => OperationException(
  graphqlErrors: [
    GraphQLError(message: 'server text', extensions: {'code': code}),
  ],
);

void main() {
  group('transactionFailureFrom', () {
    final byCode = {
      'SHOP_NOT_IN_CITY': TransactionFailure.shopNotInCity,
      'INSUFFICIENT_FUNDS': TransactionFailure.insufficientFunds,
      'ITEM_NOT_OWNED': TransactionFailure.itemNotOwned,
      'INSUFFICIENT_ITEM_QUANTITY': TransactionFailure.insufficientItemQuantity,
      'INVALID_QUANTITY': TransactionFailure.invalidQuantity,
      'ITEM_NOT_FOUND': TransactionFailure.itemNotFound,
      'ITEM_NOT_TRADABLE': TransactionFailure.itemNotTradable,
      'TRANSACTION_TOTAL_MISMATCH': TransactionFailure.totalMismatch,
      'NOT_FOUND': TransactionFailure.notFound,
      'FORBIDDEN': TransactionFailure.forbidden,
      'UNAUTHENTICATED': TransactionFailure.unauthenticated,
      'AWAITING_AID': TransactionFailure.unknown,
    };
    byCode.forEach((code, failure) {
      test('maps $code to ${failure.name}', () {
        expect(transactionFailureFrom(_withCode(code)), failure);
      });
    });

    test('maps a link error without code to connection', () {
      final exception = OperationException(
        linkException: ServerException(
          originalException: const SocketException('offline'),
        ),
      );

      expect(transactionFailureFrom(exception), TransactionFailure.connection);
    });

    test('maps an error with neither code nor link to unknown', () {
      expect(
        transactionFailureFrom(OperationException()),
        TransactionFailure.unknown,
      );
    });

    test('ignores the message text and relies on the code only', () {
      final exception = OperationException(
        graphqlErrors: [
          GraphQLError(
            message: 'Il negozio è disponibile solo in città',
            extensions: {'code': 'BOGUS'},
          ),
        ],
      );

      expect(transactionFailureFrom(exception), TransactionFailure.unknown);
    });
  });
}
