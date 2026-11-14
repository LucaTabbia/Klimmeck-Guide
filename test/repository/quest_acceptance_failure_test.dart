import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:klimmeck_guide/repository/quest_acceptance_failure.dart';

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
      'TRAVEL_STARVING': QuestAcceptanceFailure.starving,
      'UNAUTHENTICATED': QuestAcceptanceFailure.unauthenticated,
      'SOMETHING_ELSE': QuestAcceptanceFailure.unknown,
    };
    byCode.forEach((code, failure) {
      test('maps $code to ${failure.name}', () {
        expect(questAcceptanceFailureFrom(_withCode(code)), failure);
      });
    });

    test('MISSION_IN_PROGRESS maps to missionInProgress (D-13)', () {
      expect(
        questAcceptanceFailureFrom(_withCode('MISSION_IN_PROGRESS')),
        QuestAcceptanceFailure.missionInProgress,
      );
    });

    test('maps TRAVEL_STARVING to starving (D-06)', () {
      expect(
        questAcceptanceFailureFrom(_withCode('TRAVEL_STARVING')),
        QuestAcceptanceFailure.starving,
      );
    });

    test('maps QUEST_NO_EFFECT to noEffect (D-20)', () {
      expect(
        questAcceptanceFailureFrom(_withCode('QUEST_NO_EFFECT')),
        QuestAcceptanceFailure.noEffect,
      );
      expect(
        questAcceptanceFailureFrom(_fromHttp400('QUEST_NO_EFFECT')),
        QuestAcceptanceFailure.noEffect,
      );
    });

    test('BAD_USER_INPUT maps to badUserInput (D-13)', () {
      expect(
        questAcceptanceFailureFrom(_withCode('BAD_USER_INPUT')),
        QuestAcceptanceFailure.badUserInput,
      );
    });

    test(
      'BAD_USER_INPUT over HTTP 400 maps to badUserInput, not connection (D-13)',
      () {
        expect(
          questAcceptanceFailureFrom(_fromHttp400('BAD_USER_INPUT')),
          QuestAcceptanceFailure.badUserInput,
        );
      },
    );

    test('an HTTP error without a code stays connection (D-13)', () {
      final exception = OperationException(
        linkException: ServerException(statusCode: 500),
      );

      expect(
        questAcceptanceFailureFrom(exception),
        QuestAcceptanceFailure.connection,
      );
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
