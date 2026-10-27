import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:klimmeck_guide/repository/quest_result_failure.dart';

OperationException _withCode(String code) => OperationException(
  graphqlErrors: [
    GraphQLError(message: 'server text', extensions: {'code': code}),
  ],
);

void main() {
  group('questResultFailureFrom', () {
    final byCode = {
      'NOT_FOUND': QuestResultFailure.notFound,
      'FORBIDDEN': QuestResultFailure.forbidden,
      'UNAUTHENTICATED': QuestResultFailure.unauthenticated,
      'AWAITING_AID': QuestResultFailure.unknown,
    };
    byCode.forEach((code, failure) {
      test('maps $code to ${failure.name}', () {
        expect(questResultFailureFrom(_withCode(code)), failure);
      });
    });

    test('maps a link error without code to connection', () {
      final exception = OperationException(
        linkException: ServerException(
          originalException: const SocketException('offline'),
        ),
      );

      expect(questResultFailureFrom(exception), QuestResultFailure.connection);
    });

    test('maps an error with neither code nor link to unknown', () {
      expect(
        questResultFailureFrom(OperationException()),
        QuestResultFailure.unknown,
      );
    });

    test('ignores the message text and relies on the code only', () {
      final exception = OperationException(
        graphqlErrors: [
          GraphQLError(message: 'NOT_FOUND', extensions: {'code': 'BOGUS'}),
        ],
      );

      expect(questResultFailureFrom(exception), QuestResultFailure.unknown);
    });
  });

  test('QuestResultException names its failure only', () {
    expect(
      const QuestResultException(QuestResultFailure.forbidden).toString(),
      'QuestResultException(forbidden)',
    );
  });
}
