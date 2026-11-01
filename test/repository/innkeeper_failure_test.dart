import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:klimmeck_guide/repository/innkeeper_failure.dart';

OperationException _withCode(String code) => OperationException(
  graphqlErrors: [
    GraphQLError(message: 'server text', extensions: {'code': code}),
  ],
);

void main() {
  group('innkeeperFailureFrom', () {
    final byCode = {
      'NOT_FOUND': InnkeeperFailure.notFound,
      'QUEST_IN_PROGRESS': InnkeeperFailure.questInProgress,
      'OUTCOME_OVERRIDE_INVALID': InnkeeperFailure.overrideInvalid,
      'OUTCOME_NOT_PARTICIPANT': InnkeeperFailure.notParticipant,
      'FORBIDDEN': InnkeeperFailure.forbidden,
      'UNAUTHENTICATED': InnkeeperFailure.unauthenticated,
      'TRAVEL_IN_PROGRESS': InnkeeperFailure.unknown,
    };
    byCode.forEach((code, failure) {
      test('maps $code to ${failure.name}', () {
        expect(innkeeperFailureFrom(_withCode(code)), failure);
      });
    });

    test('maps a link error without code to connection', () {
      final exception = OperationException(
        linkException: ServerException(
          originalException: const SocketException('offline'),
        ),
      );

      expect(innkeeperFailureFrom(exception), InnkeeperFailure.connection);
    });

    test('maps an error with neither code nor link to unknown', () {
      expect(
        innkeeperFailureFrom(OperationException()),
        InnkeeperFailure.unknown,
      );
    });

    test('ignores the message text and relies on the code only', () {
      final exception = OperationException(
        graphqlErrors: [
          GraphQLError(
            message: 'OUTCOME_OVERRIDE_INVALID',
            extensions: {'code': 'FORBIDDEN'},
          ),
        ],
      );

      expect(innkeeperFailureFrom(exception), InnkeeperFailure.forbidden);
    });
  });

  test('InnkeeperException names its failure only', () {
    expect(
      const InnkeeperException(InnkeeperFailure.declined).toString(),
      'InnkeeperException(declined)',
    );
  });
}
