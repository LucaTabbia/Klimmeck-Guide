import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:klimmeck_guide/repository/transaction_failure.dart';

OperationException _withCode(String code) => OperationException(
  graphqlErrors: [
    GraphQLError(message: 'server text', extensions: {'code': code}),
  ],
);

OperationException _fromHttp400(String code) => OperationException(
  linkException: ServerException(
    statusCode: 400,
    parsedResponse: Response(
      response: const {},
      errors: [
        GraphQLError(message: 'server text', extensions: {'code': code}),
      ],
    ),
  ),
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
      'ITEM_NOT_IN_SHOP': TransactionFailure.itemNotInShop,
      'PET_ALREADY_OWNED': TransactionFailure.petAlreadyOwned,
      'PET_NOT_OWNED': TransactionFailure.petNotOwned,
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

    test('MISSION_IN_PROGRESS maps to missionInProgress (D-11)', () {
      expect(
        transactionFailureFrom(_withCode('MISSION_IN_PROGRESS')),
        TransactionFailure.missionInProgress,
      );
    });

    test(
      'the Phase 12 shop codes are domain failures, never unknown (D-06)',
      () {
        expect(
          [
            'ITEM_NOT_IN_SHOP',
            'PET_ALREADY_OWNED',
            'PET_NOT_OWNED',
          ].map((code) => transactionFailureFrom(_withCode(code))),
          [
            TransactionFailure.itemNotInShop,
            TransactionFailure.petAlreadyOwned,
            TransactionFailure.petNotOwned,
          ],
        );
      },
    );

    test('BAD_USER_INPUT maps to badUserInput (D-13)', () {
      expect(
        transactionFailureFrom(_withCode('BAD_USER_INPUT')),
        TransactionFailure.badUserInput,
      );
    });

    test(
      'BAD_USER_INPUT over HTTP 400 maps to badUserInput, not connection (D-13)',
      () {
        expect(
          transactionFailureFrom(_fromHttp400('BAD_USER_INPUT')),
          TransactionFailure.badUserInput,
        );
      },
    );

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
