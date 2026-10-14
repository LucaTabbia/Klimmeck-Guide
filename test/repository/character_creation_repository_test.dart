import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:klimmeck_guide/models/enums/class_type.dart';
import 'package:klimmeck_guide/models/enums/pronoun_type.dart';
import 'package:klimmeck_guide/models/enums/race_type.dart';
import 'package:klimmeck_guide/models/enums/sex_type.dart';
import 'package:klimmeck_guide/models/request/create_character_request.dart';
import 'package:klimmeck_guide/repository/character_creation_failure.dart';
import 'package:klimmeck_guide/repository/character_creation_repository.dart';
import 'package:klimmeck_guide/repository/services/image/portrait_picker.dart';
import 'package:klimmeck_guide/repository/services/rest/image_upload_exception.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/auth_fixtures.dart';
import '../helpers/fixtures/race_traits_fixture.dart';
import '../helpers/mocks.dart';

const _request = CreateCharacterRequest(
  name: 'Aldo',
  sex: SexType.male,
  pronoun: PronounType.he,
  race: RaceType.human,
  classType: ClassType.fighter,
  age: 30,
);

OperationException _graphqlCode(String code) => OperationException(
  graphqlErrors: [
    GraphQLError(message: 'server text', extensions: {'code': code}),
  ],
);

Matcher _failsWith(CharacterCreationFailure failure) => throwsA(
  isA<CharacterCreationException>().having(
    (e) => e.failure,
    'failure',
    failure,
  ),
);

void main() {
  late MockKlimmeckGraphQl graphQl;
  late MockKlimmeckRest rest;
  late MockPortraitPicker picker;
  late CharacterCreationRepository repository;

  setUpAll(() {
    registerFallbackValue(File(''));
    registerFallbackValue(PortraitSource.gallery);
    registerFallbackValue(_request);
  });

  setUp(() {
    graphQl = MockKlimmeckGraphQl();
    rest = MockKlimmeckRest();
    picker = MockPortraitPicker();
    repository = CharacterCreationRepository(
      graphQl: graphQl,
      rest: rest,
      picker: picker,
    );
  });

  group('loadRaceTraits', () {
    test('returns an unmodifiable map keyed by race', () async {
      when(
        () => graphQl.getRaceTraits(),
      ).thenAnswer((_) async => testRaceTraits.values.toList());

      final traits = await repository.loadRaceTraits();

      expect(traits, testRaceTraits);
      expect(
        () => traits[RaceType.human] = testRaceTraits[RaceType.elf]!,
        throwsUnsupportedError,
      );
    });

    test('maps a network failure to connection', () {
      when(() => graphQl.getRaceTraits()).thenThrow(
        OperationException(
          linkException: NetworkException(
            originalException: const SocketException('down'),
            uri: Uri.parse('http://x'),
          ),
        ),
      );

      expect(
        repository.loadRaceTraits(),
        _failsWith(CharacterCreationFailure.connection),
      );
    });

    test('maps a FormatException to unknown', () {
      when(() => graphQl.getRaceTraits()).thenThrow(const FormatException());

      expect(
        repository.loadRaceTraits(),
        _failsWith(CharacterCreationFailure.unknown),
      );
    });
  });

  group('pickPortrait', () {
    test('returns the path chosen by the picker', () async {
      when(
        () => picker.pick(PortraitSource.gallery),
      ).thenAnswer((_) async => '/tmp/p.jpg');

      expect(
        await repository.pickPortrait(PortraitSource.gallery),
        '/tmp/p.jpg',
      );
    });

    test('lets PortraitPickException propagate unchanged', () {
      when(() => picker.pick(any())).thenAnswer(
        (_) async => throw const PortraitPickException(
          PortraitPickFailure.permissionDenied,
        ),
      );

      expect(
        repository.pickPortrait(PortraitSource.camera),
        throwsA(isA<PortraitPickException>()),
      );
    });
  });

  group('uploadPortrait', () {
    test('uploads the local file and returns the url', () async {
      when(() => rest.uploadImage(any())).thenAnswer((_) async => 'https://u');

      final url = await repository.uploadPortrait('/tmp/p.jpg');

      expect(url, 'https://u');
      final file =
          verify(() => rest.uploadImage(captureAny())).captured.single as File;
      expect(file.path, '/tmp/p.jpg');
    });

    final failures = <String, Object>{
      'ImageUploadException': const ImageUploadException(),
      'DioException': DioException(requestOptions: RequestOptions()),
      'FileSystemException': const FileSystemException('gone'),
    };
    failures.forEach((name, error) {
      test('maps $name to uploadFailed', () {
        when(() => rest.uploadImage(any())).thenThrow(error);

        expect(
          repository.uploadPortrait('/tmp/p.jpg'),
          _failsWith(CharacterCreationFailure.uploadFailed),
        );
      });
    });
  });

  group('createCharacter', () {
    test('returns the created user', () async {
      final user = buildTestUserWithCharacter();
      when(() => graphQl.createCharacter(any())).thenAnswer((_) async => user);

      expect(await repository.createCharacter(_request), user);
    });

    test('maps CHARACTER_NAME_TAKEN to nameTaken', () {
      when(
        () => graphQl.createCharacter(any()),
      ).thenThrow(_graphqlCode('CHARACTER_NAME_TAKEN'));

      expect(
        repository.createCharacter(_request),
        _failsWith(CharacterCreationFailure.nameTaken),
      );
    });

    test('maps a FormatException to unknown', () {
      when(
        () => graphQl.createCharacter(any()),
      ).thenThrow(const FormatException());

      expect(
        repository.createCharacter(_request),
        _failsWith(CharacterCreationFailure.unknown),
      );
    });
  });

  group('fetchCurrentUser', () {
    test('returns the current user', () async {
      final user = buildTestUserWithCharacter();
      when(() => graphQl.getMe()).thenAnswer((_) async => user);

      expect(await repository.fetchCurrentUser(), user);
    });

    test('maps failures like createCharacter', () {
      when(
        () => graphQl.getMe(),
      ).thenThrow(_graphqlCode('CHARACTER_ALREADY_EXISTS'));

      expect(
        repository.fetchCurrentUser(),
        _failsWith(CharacterCreationFailure.alreadyExists),
      );
    });
  });
}
