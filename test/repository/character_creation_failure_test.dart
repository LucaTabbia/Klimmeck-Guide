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

    test('BAD_USER_INPUT maps to badUserInput (D-13)', () {
      expect(
        characterCreationFailureFrom(fromGraphqlCode('BAD_USER_INPUT')),
        CharacterCreationFailure.badUserInput,
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
    test(
      'BAD_USER_INPUT over HTTP 400 maps to badUserInput, not connection (D-13)',
      () {
        expect(
          characterCreationFailureFrom(fromHttp400('BAD_USER_INPUT')),
          CharacterCreationFailure.badUserInput,
        );
      },
    );

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

  group('portrait upload body', () {
    test('IMAGE_REJECTED in the upload body maps to imageRejected (D-13)', () {
      expect(
        portraitUploadFailureFrom({
          'statusCode': 422,
          'code': 'IMAGE_REJECTED',
          'message': 'Immagine non ammessa',
          'reasons': ['nudity'],
        }),
        CharacterCreationFailure.imageRejected,
      );
    });

    test(
      'IMAGE_MODERATION_UNAVAILABLE in the upload body maps to moderationUnavailable (D-13)',
      () {
        expect(
          portraitUploadFailureFrom({
            'statusCode': 503,
            'code': 'IMAGE_MODERATION_UNAVAILABLE',
            'message': 'x',
          }),
          CharacterCreationFailure.moderationUnavailable,
        );
      },
    );

    test('an upload body without a known code stays uploadFailed (D-13)', () {
      for (final body in <Object?>[
        null,
        'text',
        {'code': 42},
        {'code': 'OTHER'},
      ]) {
        expect(
          portraitUploadFailureFrom(body),
          CharacterCreationFailure.uploadFailed,
          reason: '$body',
        );
      }
    });
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
