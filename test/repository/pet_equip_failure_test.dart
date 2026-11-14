import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:klimmeck_guide/repository/pet_equip_failure.dart';

OperationException _withCode(String code) => OperationException(
  graphqlErrors: [
    GraphQLError(message: 'server text', extensions: {'code': code}),
  ],
);

void main() {
  group('petEquipFailureFrom', () {
    test('maps PET_NOT_OWNED to notOwned (D-06)', () {
      expect(
        petEquipFailureFrom(_withCode('PET_NOT_OWNED')),
        PetEquipFailure.notOwned,
      );
    });

    test('maps NOT_FOUND / FORBIDDEN / BAD_USER_INPUT / UNAUTHENTICATED', () {
      final byCode = {
        'NOT_FOUND': PetEquipFailure.notFound,
        'FORBIDDEN': PetEquipFailure.forbidden,
        'BAD_USER_INPUT': PetEquipFailure.badUserInput,
        'UNAUTHENTICATED': PetEquipFailure.unauthenticated,
      };
      byCode.forEach((code, failure) {
        expect(petEquipFailureFrom(_withCode(code)), failure, reason: code);
      });
    });

    test('MISSION_IN_PROGRESS maps to missionInProgress (D-11)', () {
      expect(
        petEquipFailureFrom(_withCode('MISSION_IN_PROGRESS')),
        PetEquipFailure.missionInProgress,
      );
    });

    test('maps a link error without code to connection', () {
      final exception = OperationException(
        linkException: ServerException(
          originalException: const SocketException('offline'),
        ),
      );

      expect(petEquipFailureFrom(exception), PetEquipFailure.connection);
    });

    test('maps an unknown code to unknown', () {
      expect(
        petEquipFailureFrom(_withCode('PET_ALREADY_OWNED')),
        PetEquipFailure.unknown,
      );
      expect(
        petEquipFailureFrom(OperationException()),
        PetEquipFailure.unknown,
      );
    });

    test('ignores the message text and relies on the code only', () {
      final exception = OperationException(
        graphqlErrors: [
          GraphQLError(
            message: 'PET_NOT_OWNED',
            extensions: {'code': 'FORBIDDEN'},
          ),
        ],
      );

      expect(petEquipFailureFrom(exception), PetEquipFailure.forbidden);
    });
  });

  test('PetEquipException prints only the failure name', () {
    expect(
      const PetEquipException(PetEquipFailure.notOwned).toString(),
      'PetEquipException(notOwned)',
    );
  });
}
