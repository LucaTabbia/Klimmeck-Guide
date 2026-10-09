import 'package:flutter_test/flutter_test.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:klimmeck_guide/repository/character_creation_failure.dart';

GraphQLError errorWithCode(String code) =>
    GraphQLError(message: 'server text', extensions: {'code': code});

OperationException fromGraphqlCode(String code) =>
    OperationException(graphqlErrors: [errorWithCode(code)]);

OperationException fromHttp400(String code) => OperationException(
  linkException: ServerException(
    statusCode: 400,
    parsedResponse: Response(response: const {}, errors: [errorWithCode(code)]),
  ),
);

void main() {
  group('graphqlErrors path', () {
    const expectations = {
      'CHARACTER_NAME_INVALID': CharacterCreationFailure.nameInvalid,
      'CHARACTER_NAME_TAKEN': CharacterCreationFailure.nameTaken,
      'CHARACTER_AGE_OUT_OF_RANGE': CharacterCreationFailure.ageOutOfRange,
      'CHARACTER_ALREADY_EXISTS': CharacterCreationFailure.alreadyExists,
      'STARTING_LOCATION_UNAVAILABLE':
          CharacterCreationFailure.startingLocationUnavailable,
    };

    expectations.forEach((code, failure) {
      test('$code maps to ${failure.name}', () {
        expect(characterCreationFailureFrom(fromGraphqlCode(code)), failure);
      });
    });

    test('BAD_USER_INPUT maps to unknown', () {
      expect(
        characterCreationFailureFrom(fromGraphqlCode('BAD_USER_INPUT')),
        CharacterCreationFailure.unknown,
      );
    });

    test('an unrecognised code maps to unknown', () {
      expect(
        characterCreationFailureFrom(fromGraphqlCode('SOMETHING_NEW')),
        CharacterCreationFailure.unknown,
      );
    });

    test('no code and no link exception maps to unknown', () {
      expect(
        characterCreationFailureFrom(OperationException()),
        CharacterCreationFailure.unknown,
      );
    });
  });

  group('HTTP 400 parsedResponse path', () {
    test('BAD_USER_INPUT maps to unknown, not connection', () {
      expect(
        characterCreationFailureFrom(fromHttp400('BAD_USER_INPUT')),
        CharacterCreationFailure.unknown,
      );
    });

    test('CHARACTER_NAME_TAKEN maps to nameTaken', () {
      expect(
        characterCreationFailureFrom(fromHttp400('CHARACTER_NAME_TAKEN')),
        CharacterCreationFailure.nameTaken,
      );
    });
  });

  group('network failures', () {
    test('NetworkException without a code maps to connection', () {
      final exception = OperationException(
        linkException: NetworkException(
          originalException: Exception('offline'),
          uri: Uri.parse('http://x'),
        ),
      );

      expect(
        characterCreationFailureFrom(exception),
        CharacterCreationFailure.connection,
      );
    });

    test(
      'ServerException 500 without a parsed response maps to connection',
      () {
        final exception = OperationException(
          linkException: ServerException(statusCode: 500),
        );

        expect(
          characterCreationFailureFrom(exception),
          CharacterCreationFailure.connection,
        );
      },
    );
  });

  test('graphqlErrors win over the parsedResponse errors', () {
    final exception = OperationException(
      graphqlErrors: [errorWithCode('CHARACTER_NAME_INVALID')],
      linkException: ServerException(
        statusCode: 400,
        parsedResponse: Response(
          response: const {},
          errors: [errorWithCode('CHARACTER_NAME_TAKEN')],
        ),
      ),
    );

    expect(
      characterCreationFailureFrom(exception),
      CharacterCreationFailure.nameInvalid,
    );
  });
}
