import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:klimmeck_guide/repository/character_deletion_failure.dart';
import 'package:klimmeck_guide/repository/character_deletion_repository.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/auth_fixtures.dart';
import '../helpers/mocks.dart';

OperationException _graphqlCode(String code) => OperationException(
  graphqlErrors: [
    GraphQLError(message: 'server text', extensions: {'code': code}),
  ],
);

Matcher _failsWith(CharacterDeletionFailure failure) => throwsA(
  isA<CharacterDeletionException>().having(
    (e) => e.failure,
    'failure',
    failure,
  ),
);

void main() {
  late MockKlimmeckGraphQl graphQl;
  late CharacterDeletionRepository repository;

  setUp(() {
    graphQl = MockKlimmeckGraphQl();
    repository = CharacterDeletionRepository(graphQl: graphQl);
  });

  group('deleteCurrentCharacter', () {
    test('returns the user from the mutation', () async {
      final user = buildTestUser();
      when(() => graphQl.deleteCharacter()).thenAnswer((_) async => user);

      expect(await repository.deleteCurrentCharacter(), user);
    });

    test('maps CHARACTER_NOT_FOUND to notFound', () {
      when(
        () => graphQl.deleteCharacter(),
      ).thenThrow(_graphqlCode('CHARACTER_NOT_FOUND'));

      expect(
        repository.deleteCurrentCharacter(),
        _failsWith(CharacterDeletionFailure.notFound),
      );
    });

    test('maps a FormatException to unknown', () {
      when(() => graphQl.deleteCharacter()).thenThrow(const FormatException());

      expect(
        repository.deleteCurrentCharacter(),
        _failsWith(CharacterDeletionFailure.unknown),
      );
    });
  });

  group('fetchCurrentUser', () {
    test('returns the current user', () async {
      final user = buildTestUserWithCharacter();
      when(() => graphQl.getMe()).thenAnswer((_) async => user);

      expect(await repository.fetchCurrentUser(), user);
    });

    test('maps a link error to connection', () {
      when(() => graphQl.getMe()).thenThrow(
        OperationException(
          linkException: ServerException(
            originalException: const SocketException('down'),
          ),
        ),
      );

      expect(
        repository.fetchCurrentUser(),
        _failsWith(CharacterDeletionFailure.connection),
      );
    });
  });
}
