import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:klimmeck_guide/repository/quest_abandon_failure.dart';

OperationException _withCode(String code) => OperationException(
  graphqlErrors: [
    GraphQLError(message: 'server text', extensions: {'code': code}),
  ],
);

void main() {
  group('questAbandonFailureFrom', () {
    final byCode = {
      'QUEST_NOT_WAITING': QuestAbandonFailure.notWaiting,
      'NOT_FOUND': QuestAbandonFailure.notFound,
      'FORBIDDEN': QuestAbandonFailure.forbidden,
      'UNAUTHENTICATED': QuestAbandonFailure.unauthenticated,
      'SOMETHING_ELSE': QuestAbandonFailure.unknown,
    };
    byCode.forEach((code, failure) {
      test('maps $code to ${failure.name}', () {
        expect(questAbandonFailureFrom(_withCode(code)), failure);
      });
    });

    test('maps a link error without code to connection', () {
      final exception = OperationException(
        linkException: ServerException(
          originalException: const SocketException('x'),
        ),
      );

      expect(
        questAbandonFailureFrom(exception),
        QuestAbandonFailure.connection,
      );
    });

    test('ignores the message text and relies on the code only', () {
      final exception = OperationException(
        graphqlErrors: [GraphQLError(message: 'QUEST_NOT_WAITING')],
      );

      expect(questAbandonFailureFrom(exception), QuestAbandonFailure.unknown);
    });
  });
}
