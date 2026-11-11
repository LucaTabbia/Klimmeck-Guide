import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:klimmeck_guide/repository/item_use_failure.dart';

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

void main() {
  group('itemUseFailureFrom', () {
    test('maps every refusal code to its failure (D-11)', () {
      const byCode = {
        'AWAITING_AID': ItemUseFailure.awaitingAid,
        'ITEM_NOT_OWNED': ItemUseFailure.notOwned,
        'ITEM_NOT_USABLE': ItemUseFailure.notUsable,
        'POTION_RECOVERING': ItemUseFailure.potionRecovering,
        'ITEM_NO_EFFECT': ItemUseFailure.noEffect,
        'BAD_USER_INPUT': ItemUseFailure.badUserInput,
        'UNAUTHENTICATED': ItemUseFailure.unauthenticated,
        'SOMETHING_ELSE': ItemUseFailure.unknown,
      };
      byCode.forEach((code, failure) {
        _shapes.forEach((shape, build) {
          expect(
            itemUseFailureFrom(build({'code': code})),
            failure,
            reason: '$code via $shape',
          );
        });
      });
    });

    test('a link error without a code is a connection failure (D-11)', () {
      final exception = OperationException(
        linkException: ServerException(
          originalException: const SocketException('x'),
        ),
      );

      expect(itemUseFailureFrom(exception), ItemUseFailure.connection);
    });

    test('an error with neither code nor link is unknown (D-11)', () {
      expect(itemUseFailureFrom(OperationException()), ItemUseFailure.unknown);
    });

    test('ignores the message text and relies on the code only (D-11)', () {
      final exception = OperationException(
        graphqlErrors: [GraphQLError(message: 'POTION_RECOVERING')],
      );

      expect(itemUseFailureFrom(exception), ItemUseFailure.unknown);
    });
  });

  group('itemUseExceptionFrom', () {
    test('the server recoveryUntil travels on the exception (D-19)', () {
      _shapes.forEach((shape, build) {
        final exception = itemUseExceptionFrom(
          build({
            'code': 'POTION_RECOVERING',
            'recoveryUntil': '2026-10-27T10:30:00.000Z',
          }),
        );

        expect(
          exception.failure,
          ItemUseFailure.potionRecovering,
          reason: shape,
        );
        expect(
          exception.recoveryUntil,
          DateTime.utc(2026, 10, 27, 10, 30),
          reason: shape,
        );
        expect(exception.recoveryUntil!.isUtc, isTrue, reason: shape);
      });
    });

    test('a POTION_RECOVERING without a readable recoveryUntil carries no date '
        '(D-19)', () {
      final unreadable = <Map<String, dynamic>>[
        {'code': 'POTION_RECOVERING'},
        {'code': 'POTION_RECOVERING', 'recoveryUntil': 42},
        {'code': 'POTION_RECOVERING', 'recoveryUntil': 'soon'},
      ];
      for (final extensions in unreadable) {
        _shapes.forEach((shape, build) {
          final exception = itemUseExceptionFrom(build(extensions));

          expect(
            exception.failure,
            ItemUseFailure.potionRecovering,
            reason: '$extensions via $shape',
          );
          expect(
            exception.recoveryUntil,
            isNull,
            reason: '$extensions via $shape',
          );
        });
      }
    });

    test('other failures never carry a date (D-19)', () {
      final exception = itemUseExceptionFrom(
        _withExtensions({
          'code': 'ITEM_NO_EFFECT',
          'recoveryUntil': '2026-10-27T10:30:00.000Z',
        }),
      );

      expect(exception.failure, ItemUseFailure.noEffect);
      expect(exception.recoveryUntil, isNull);
    });

    test('the exception prints the failure name only (D-19)', () {
      final exception = ItemUseException(
        ItemUseFailure.potionRecovering,
        recoveryUntil: DateTime.utc(2026, 10, 27, 10, 30),
      );

      expect(exception.toString(), 'ItemUseException(potionRecovering)');
    });
  });
}
