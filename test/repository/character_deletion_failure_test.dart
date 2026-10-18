import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:klimmeck_guide/repository/character_deletion_failure.dart';

OperationException _withCode(String code) => OperationException(
  graphqlErrors: [
    GraphQLError(message: 'server text', extensions: {'code': code}),
  ],
);

void main() {
  group('characterDeletionFailureFrom', () {
    final byCode = {
      'CHARACTER_NOT_FOUND': CharacterDeletionFailure.notFound,
      'UNAUTHENTICATED': CharacterDeletionFailure.unauthenticated,
      'GRAPHQL_VALIDATION_FAILED': CharacterDeletionFailure.unknown,
      'SOMETHING_ELSE': CharacterDeletionFailure.unknown,
    };
    byCode.forEach((code, failure) {
      test('maps $code to ${failure.name}', () {
        expect(characterDeletionFailureFrom(_withCode(code)), failure);
      });
    });

    test('maps a link error without code to connection', () {
      final exception = OperationException(
        linkException: ServerException(
          originalException: const SocketException('x'),
        ),
      );

      expect(
        characterDeletionFailureFrom(exception),
        CharacterDeletionFailure.connection,
      );
    });

    test('maps no code and no link error to unknown', () {
      expect(
        characterDeletionFailureFrom(OperationException()),
        CharacterDeletionFailure.unknown,
      );
    });

    test('never reads the message text', () {
      final exception = OperationException(
        graphqlErrors: [GraphQLError(message: 'CHARACTER_NOT_FOUND')],
      );

      expect(
        characterDeletionFailureFrom(exception),
        CharacterDeletionFailure.unknown,
      );
    });
  });

  test('CharacterDeletionException prints the failure name', () {
    const exception = CharacterDeletionException(
      CharacterDeletionFailure.notFound,
    );

    expect(exception.toString(), 'CharacterDeletionException(notFound)');
  });
}
