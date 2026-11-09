import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:klimmeck_guide/repository/travel_failure.dart';

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
  group('travelFailureFrom', () {
    final byCode = {
      'TRAVEL_IN_PROGRESS': TravelFailure.inProgress,
      'TRAVEL_SAME_LOCATION': TravelFailure.sameLocation,
      'TRAVEL_DESTINATION_NOT_ALLOWED': TravelFailure.destinationNotAllowed,
      'TRAVEL_NO_PATH': TravelFailure.noPath,
      'QUEST_IN_PROGRESS': TravelFailure.questInProgress,
      'AWAITING_AID': TravelFailure.awaitingAid,
      'TRAVEL_STARVING': TravelFailure.starving,
      'NOT_FOUND': TravelFailure.notFound,
      'FORBIDDEN': TravelFailure.forbidden,
      'UNAUTHENTICATED': TravelFailure.unauthenticated,
      'QUEST_FULL': TravelFailure.unknown,
    };
    byCode.forEach((code, failure) {
      test('maps $code to ${failure.name}', () {
        expect(travelFailureFrom(_withCode(code)), failure);
      });
    });

    test('maps TRAVEL_STARVING to starving (D-06)', () {
      expect(
        travelFailureFrom(_withCode('TRAVEL_STARVING')),
        TravelFailure.starving,
      );
    });

    test('BAD_USER_INPUT maps to badUserInput (D-13)', () {
      expect(
        travelFailureFrom(_withCode('BAD_USER_INPUT')),
        TravelFailure.badUserInput,
      );
    });

    test(
      'BAD_USER_INPUT over HTTP 400 maps to badUserInput, not connection (D-13)',
      () {
        expect(
          travelFailureFrom(_fromHttp400('BAD_USER_INPUT')),
          TravelFailure.badUserInput,
        );
      },
    );

    test('an HTTP error without a code stays connection (D-13)', () {
      final exception = OperationException(
        linkException: ServerException(statusCode: 500),
      );

      expect(travelFailureFrom(exception), TravelFailure.connection);
    });

    test('maps a link error without code to connection', () {
      final exception = OperationException(
        linkException: ServerException(
          originalException: const SocketException('offline'),
        ),
      );

      expect(travelFailureFrom(exception), TravelFailure.connection);
    });

    test('maps an error with neither code nor link to unknown', () {
      expect(travelFailureFrom(OperationException()), TravelFailure.unknown);
    });

    test('ignores the message text and relies on the code only', () {
      final exception = OperationException(
        graphqlErrors: [
          GraphQLError(
            message: 'TRAVEL_NO_PATH',
            extensions: {'code': 'FORBIDDEN'},
          ),
        ],
      );

      expect(travelFailureFrom(exception), TravelFailure.forbidden);
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

      expect(travelFailureFrom(exception), TravelFailure.unknown);
    });
  });

  test('TravelException prints the failure name only', () {
    expect(
      const TravelException(TravelFailure.noPath).toString(),
      'TravelException(noPath)',
    );
  });
}
