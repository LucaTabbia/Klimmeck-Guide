import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:klimmeck_guide/repository/pet_rename_failure.dart';

OperationException _withCode(String code) => OperationException(
  graphqlErrors: [
    GraphQLError(message: 'server text', extensions: {'code': code}),
  ],
);

void main() {
  group('petRenameFailureFrom', () {
    test('PET_NAME_INVALID maps to nameInvalid (D-31)', () {
      expect(petNameInvalidCode, 'PET_NAME_INVALID');
      expect(
        petRenameFailureFrom(_withCode('PET_NAME_INVALID')),
        PetRenameFailure.nameInvalid,
      );
    });

    test('CHARACTER_NAME_INVALID maps to nameInvalid too (D-31)', () {
      expect(
        petRenameFailureFrom(_withCode('CHARACTER_NAME_INVALID')),
        PetRenameFailure.nameInvalid,
      );
    });

    test('PET_NOT_OWNED and NOT_FOUND map to notOwned and notFound (D-19)', () {
      expect(
        petRenameFailureFrom(_withCode('PET_NOT_OWNED')),
        PetRenameFailure.notOwned,
      );
      expect(
        petRenameFailureFrom(_withCode('NOT_FOUND')),
        PetRenameFailure.notFound,
      );
    });

    test('BAD_USER_INPUT and UNAUTHENTICATED map to their failure (D-19)', () {
      expect(
        petRenameFailureFrom(_withCode('BAD_USER_INPUT')),
        PetRenameFailure.badUserInput,
      );
      expect(
        petRenameFailureFrom(_withCode('UNAUTHENTICATED')),
        PetRenameFailure.unauthenticated,
      );
    });

    test('a link error without code maps to connection (D-19)', () {
      final exception = OperationException(
        linkException: ServerException(
          originalException: const SocketException('offline'),
        ),
      );

      expect(petRenameFailureFrom(exception), PetRenameFailure.connection);
    });

    test('an unknown code, and MISSION_IN_PROGRESS, map to unknown '
        '(D-31: the rename is not locked)', () {
      expect(
        petRenameFailureFrom(_withCode('MISSION_IN_PROGRESS')),
        PetRenameFailure.unknown,
      );
      expect(
        petRenameFailureFrom(_withCode('PET_ALREADY_OWNED')),
        PetRenameFailure.unknown,
      );
      expect(
        petRenameFailureFrom(OperationException()),
        PetRenameFailure.unknown,
      );
    });

    test('ignores the message text and relies on the code only', () {
      final exception = OperationException(
        graphqlErrors: [
          GraphQLError(
            message: 'PET_NAME_INVALID',
            extensions: {'code': 'NOT_FOUND'},
          ),
        ],
      );

      expect(petRenameFailureFrom(exception), PetRenameFailure.notFound);
    });
  });

  test('PetRenameException prints only the failure name', () {
    expect(
      const PetRenameException(PetRenameFailure.nameInvalid).toString(),
      'PetRenameException(nameInvalid)',
    );
  });
}
