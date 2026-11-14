import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:klimmeck_guide/repository/equipment_failure.dart';

OperationException _withCode(String code) => OperationException(
  graphqlErrors: [
    GraphQLError(message: 'server text', extensions: {'code': code}),
  ],
);

void main() {
  group('equipmentFailureFrom', () {
    test('MISSION_IN_PROGRESS maps to missionInProgress (D-11)', () {
      expect(
        equipmentFailureFrom(_withCode('MISSION_IN_PROGRESS')),
        EquipmentFailure.missionInProgress,
      );
    });

    test('maps NOT_FOUND to notFound', () {
      expect(
        equipmentFailureFrom(_withCode('NOT_FOUND')),
        EquipmentFailure.notFound,
      );
    });

    test('maps FORBIDDEN to forbidden', () {
      expect(
        equipmentFailureFrom(_withCode('FORBIDDEN')),
        EquipmentFailure.forbidden,
      );
    });

    test('maps BAD_USER_INPUT to badUserInput', () {
      expect(
        equipmentFailureFrom(_withCode('BAD_USER_INPUT')),
        EquipmentFailure.badUserInput,
      );
    });

    test('maps UNAUTHENTICATED to unauthenticated', () {
      expect(
        equipmentFailureFrom(_withCode('UNAUTHENTICATED')),
        EquipmentFailure.unauthenticated,
      );
    });

    test('maps an unknown code to unknown', () {
      expect(
        equipmentFailureFrom(_withCode('ITEM_ALREADY_EQUIPPED')),
        EquipmentFailure.unknown,
      );
      expect(
        equipmentFailureFrom(OperationException()),
        EquipmentFailure.unknown,
      );
    });

    test('a link error without code is connection (LB-1)', () {
      final exception = OperationException(
        linkException: ServerException(
          originalException: const SocketException('offline'),
        ),
      );

      expect(equipmentFailureFrom(exception), EquipmentFailure.connection);
    });

    test('ignores the message text and relies on the code only', () {
      final exception = OperationException(
        graphqlErrors: [
          GraphQLError(
            message: 'MISSION_IN_PROGRESS',
            extensions: {'code': 'FORBIDDEN'},
          ),
        ],
      );

      expect(equipmentFailureFrom(exception), EquipmentFailure.forbidden);
    });
  });

  test('EquipmentException prints only the failure name', () {
    expect(
      const EquipmentException(EquipmentFailure.declined).toString(),
      'EquipmentException(declined)',
    );
  });
}
