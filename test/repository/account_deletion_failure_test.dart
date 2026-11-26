import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:klimmeck_guide/repository/account_deletion_failure.dart';

import '../helpers/fakes/fake_account_deletion_api.dart';

void main() {
  group('accountDeletionFailureFrom', () {
    test('INNKEEPER_ACCOUNT_PROTECTED maps to innkeeperProtected (D-16)', () {
      expect(
        accountDeletionFailureFrom(
          operationExceptionWithCode('INNKEEPER_ACCOUNT_PROTECTED'),
        ),
        AccountDeletionFailure.innkeeperProtected,
      );
    });

    test('UNAUTHENTICATED maps to unauthenticated', () {
      expect(
        accountDeletionFailureFrom(
          operationExceptionWithCode('UNAUTHENTICATED'),
        ),
        AccountDeletionFailure.unauthenticated,
      );
    });

    test('a link failure without a code is a connection failure', () {
      final exception = OperationException(
        linkException: ServerException(
          originalException: const SocketException('x'),
        ),
      );

      expect(
        accountDeletionFailureFrom(exception),
        AccountDeletionFailure.connection,
      );
    });

    test('a rate-limit refusal falls back to the generic failure (D-20)', () {
      expect(
        accountDeletionFailureFrom(
          operationExceptionWithCode('TOO_MANY_REQUESTS'),
        ),
        AccountDeletionFailure.unknown,
      );
    });

    test('an unknown code is unknown', () {
      expect(
        accountDeletionFailureFrom(operationExceptionWithCode('SOMETHING')),
        AccountDeletionFailure.unknown,
      );
    });

    test('the server message is never read', () {
      final first = operationExceptionWithCode(
        'SOMETHING',
        message: 'INNKEEPER_ACCOUNT_PROTECTED',
      );
      final second = operationExceptionWithCode(
        'SOMETHING',
        message: 'Errore di connessione',
      );
      final withoutCode = OperationException(
        graphqlErrors: [GraphQLError(message: 'UNAUTHENTICATED')],
      );

      expect(accountDeletionFailureFrom(first), AccountDeletionFailure.unknown);
      expect(
        accountDeletionFailureFrom(second),
        AccountDeletionFailure.unknown,
      );
      expect(
        accountDeletionFailureFrom(withoutCode),
        AccountDeletionFailure.unknown,
      );
    });
  });

  test('AccountDeletionException prints the failure name', () {
    const exception = AccountDeletionException(
      AccountDeletionFailure.innkeeperProtected,
    );

    expect(
      exception.toString(),
      'AccountDeletionException(innkeeperProtected)',
    );
  });
}
