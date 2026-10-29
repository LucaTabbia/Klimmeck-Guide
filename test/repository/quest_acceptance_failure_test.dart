import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:klimmeck_guide/repository/quest_acceptance_failure.dart';

OperationException _withCode(String code) => OperationException(
  graphqlErrors: [
    GraphQLError(message: 'server text', extensions: {'code': code}),
  ],
);

void main() {
  group('questAcceptanceFailureFrom', () {
    final byCode = {
      'QUEST_SLOT_BUSY': QuestAcceptanceFailure.slotBusy,
      'QUEST_FULL': QuestAcceptanceFailure.full,
      'QUEST_ALREADY_TAKEN': QuestAcceptanceFailure.alreadyTaken,
      'QUEST_TITLE_MISMATCH': QuestAcceptanceFailure.titleMismatch,
      'QUEST_NOT_IN_CITY': QuestAcceptanceFailure.notInCity,
      'QUEST_NOT_ACCEPTABLE': QuestAcceptanceFailure.notAcceptable,
      'INSUFFICIENT_POINTS': QuestAcceptanceFailure.insufficientPoints,
      'NOT_FOUND': QuestAcceptanceFailure.notFound,
      'FORBIDDEN': QuestAcceptanceFailure.forbidden,
      'TRAVEL_IN_PROGRESS': QuestAcceptanceFailure.travelInProgress,
      'AWAITING_AID': QuestAcceptanceFailure.awaitingAid,
      'UNAUTHENTICATED': QuestAcceptanceFailure.unauthenticated,
      'SOMETHING_ELSE': QuestAcceptanceFailure.unknown,
    };
    byCode.forEach((code, failure) {
      test('maps $code to ${failure.name}', () {
        expect(questAcceptanceFailureFrom(_withCode(code)), failure);
      });
    });

    test('maps a link error without code to connection', () {
      final exception = OperationException(
        linkException: ServerException(
          originalException: const SocketException('x'),
        ),
      );

      expect(
        questAcceptanceFailureFrom(exception),
        QuestAcceptanceFailure.connection,
      );
    });

    test('maps an error with neither code nor link to unknown', () {
      expect(
        questAcceptanceFailureFrom(OperationException()),
        QuestAcceptanceFailure.unknown,
      );
    });

    test('ignores the message text and relies on the code only', () {
      final exception = OperationException(
        graphqlErrors: [GraphQLError(message: 'Punti canale insufficienti')],
      );

      expect(
        questAcceptanceFailureFrom(exception),
        QuestAcceptanceFailure.unknown,
      );
    });

    test('ignores the awaiting-aid message under an unknown code', () {
      final exception = OperationException(
        graphqlErrors: [
          GraphQLError(
            message: 'Il tuo personaggio è in attesa di soccorso',
            extensions: {'code': 'BOGUS'},
          ),
        ],
      );

      expect(
        questAcceptanceFailureFrom(exception),
        QuestAcceptanceFailure.unknown,
      );
    });
  });

  test('QuestAcceptanceException prints the failure name only', () {
    expect(
      const QuestAcceptanceException(QuestAcceptanceFailure.full).toString(),
      'QuestAcceptanceException(full)',
    );
  });
}
