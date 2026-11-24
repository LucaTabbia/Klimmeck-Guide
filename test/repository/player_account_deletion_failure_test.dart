import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:klimmeck_guide/repository/player_account_deletion_failure.dart';

import '../helpers/fakes/fake_account_deletion_api.dart';

PlayerAccountDeletionFailure _failureOf(String code) =>
    playerAccountDeletionFailureFrom(operationExceptionWithCode(code));

void main() {
  group('playerAccountDeletionFailureFrom', () {
    test('TWITCH_USER_NOT_FOUND maps to twitchUserNotFound (D-15)', () {
      expect(
        _failureOf('TWITCH_USER_NOT_FOUND'),
        PlayerAccountDeletionFailure.twitchUserNotFound,
      );
    });

    test('ACCOUNT_NOT_FOUND maps to accountNotFound (D-15)', () {
      expect(
        _failureOf('ACCOUNT_NOT_FOUND'),
        PlayerAccountDeletionFailure.accountNotFound,
      );
    });

    test('INNKEEPER_ACCOUNT_PROTECTED maps to innkeeperProtected (D-16)', () {
      expect(
        _failureOf('INNKEEPER_ACCOUNT_PROTECTED'),
        PlayerAccountDeletionFailure.innkeeperProtected,
      );
    });

    test('TWITCH_UNAVAILABLE maps to twitchUnavailable (D-15)', () {
      expect(
        _failureOf('TWITCH_UNAVAILABLE'),
        PlayerAccountDeletionFailure.twitchUnavailable,
      );
    });

    test('a link failure without a code is a connection failure', () {
      final exception = OperationException(
        linkException: ServerException(
          originalException: const SocketException('x'),
        ),
      );

      expect(
        playerAccountDeletionFailureFrom(exception),
        PlayerAccountDeletionFailure.connection,
      );
    });

    test('FORBIDDEN and unknown codes are unknown', () {
      expect(_failureOf('FORBIDDEN'), PlayerAccountDeletionFailure.unknown);
      expect(_failureOf('SOMETHING'), PlayerAccountDeletionFailure.unknown);
    });

    test('the server message is never read', () {
      final withCode = operationExceptionWithCode(
        'SOMETHING',
        message: 'TWITCH_USER_NOT_FOUND',
      );
      final withoutCode = OperationException(
        graphqlErrors: [GraphQLError(message: 'ACCOUNT_NOT_FOUND')],
      );

      expect(
        playerAccountDeletionFailureFrom(withCode),
        PlayerAccountDeletionFailure.unknown,
      );
      expect(
        playerAccountDeletionFailureFrom(withoutCode),
        PlayerAccountDeletionFailure.unknown,
      );
    });
  });

  test('PlayerAccountDeletionException prints only the failure name', () {
    const exception = PlayerAccountDeletionException(
      PlayerAccountDeletionFailure.accountNotFound,
    );

    expect(
      exception.toString(),
      'PlayerAccountDeletionException(accountNotFound)',
    );
  });
}
