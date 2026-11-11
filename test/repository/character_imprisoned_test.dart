import 'package:flutter_test/flutter_test.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:klimmeck_guide/repository/character_imprisoned.dart';
import 'package:klimmeck_guide/repository/quest_acceptance_failure.dart';
import 'package:klimmeck_guide/repository/transaction_failure.dart';
import 'package:klimmeck_guide/repository/travel_failure.dart';

OperationException _withExtensions(Map<String, dynamic> extensions) =>
    OperationException(
      graphqlErrors: [
        GraphQLError(message: 'server text', extensions: extensions),
      ],
    );

OperationException _fromHttp400(Map<String, dynamic> extensions) =>
    OperationException(
      linkException: ServerException(
        statusCode: 400,
        parsedResponse: Response(
          response: const {},
          errors: [
            GraphQLError(message: 'server text', extensions: extensions),
          ],
        ),
      ),
    );

const _shapes = <String, OperationException Function(Map<String, dynamic>)>{
  'graphql error': _withExtensions,
  'HTTP 400': _fromHttp400,
};

const _releaseWire = '2026-11-10T22:00:00.000Z';
final _release = DateTime.utc(2026, 11, 10, 22);

Map<String, dynamic> _imprisoned([Object? until = _releaseWire]) => {
  'code': 'CHARACTER_IMPRISONED',
  'imprisonedUntil': until,
};

void main() {
  group('imprisonedUntilFrom', () {
    test('reads the release instant of a CHARACTER_IMPRISONED refusal as UTC '
        '(quick 261110-cgd)', () {
      _shapes.forEach((shape, build) {
        final release = imprisonedUntilFrom(build(_imprisoned()));

        expect(release, _release, reason: shape);
        expect(release!.isUtc, isTrue, reason: shape);
      });
    });

    test('a missing or malformed release is null (quick 261110-cgd)', () {
      for (final until in <Object?>[null, 'soon', 42]) {
        expect(
          imprisonedUntilFrom(_withExtensions(_imprisoned(until))),
          isNull,
        );
      }
    });

    test('another code never yields a release (quick 261110-cgd)', () {
      final exception = _withExtensions({
        'code': 'AWAITING_AID',
        'imprisonedUntil': _releaseWire,
      });

      expect(imprisonedUntilFrom(exception), isNull);
    });
  });

  group('CHARACTER_IMPRISONED in the four operations', () {
    test('quest acceptance maps it to imprisoned with the release '
        '(quick 261110-cgd)', () {
      _shapes.forEach((shape, build) {
        final exception = questAcceptanceExceptionFrom(build(_imprisoned()));

        expect(
          exception.failure,
          QuestAcceptanceFailure.imprisoned,
          reason: shape,
        );
        expect(exception.imprisonedUntil, _release, reason: shape);
      });
    });

    test('travel start and preview map it to imprisoned with the release '
        '(quick 261110-cgd)', () {
      _shapes.forEach((shape, build) {
        final exception = travelExceptionFrom(build(_imprisoned()));

        expect(exception.failure, TravelFailure.imprisoned, reason: shape);
        expect(exception.imprisonedUntil, _release, reason: shape);
      });
    });

    test('the shop transaction maps it to imprisoned (quick 261110-cgd)', () {
      _shapes.forEach((shape, build) {
        expect(
          transactionFailureFrom(build(_imprisoned())),
          TransactionFailure.imprisoned,
          reason: shape,
        );
      });
    });

    test('other refusals carry no release (quick 261110-cgd)', () {
      final busy = _withExtensions({'code': 'QUEST_SLOT_BUSY'});
      final travelling = _withExtensions({'code': 'TRAVEL_IN_PROGRESS'});

      expect(questAcceptanceExceptionFrom(busy).imprisonedUntil, isNull);
      expect(
        questAcceptanceExceptionFrom(busy).failure,
        QuestAcceptanceFailure.slotBusy,
      );
      expect(travelExceptionFrom(travelling).imprisonedUntil, isNull);
      expect(travelExceptionFrom(travelling).failure, TravelFailure.inProgress);
    });
  });
}
