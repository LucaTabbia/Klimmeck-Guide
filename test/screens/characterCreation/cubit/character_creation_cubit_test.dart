import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/enums/class_type.dart';
import 'package:klimmeck_guide/models/enums/pronoun_type.dart';
import 'package:klimmeck_guide/models/enums/race_type.dart';
import 'package:klimmeck_guide/models/enums/sex_type.dart';
import 'package:klimmeck_guide/models/user.dart';
import 'package:klimmeck_guide/repository/character_creation_failure.dart';
import 'package:klimmeck_guide/repository/services/image/portrait_picker.dart';
import 'package:klimmeck_guide/screens/characterCreation/cubit/character_creation_cubit.dart';
import 'package:klimmeck_guide/screens/characterCreation/cubit/character_draft.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/auth_fixtures.dart';
import '../../../helpers/fixtures/race_traits_fixture.dart';
import '../../../helpers/mocks.dart';

const _connectionError = CharacterCreationException(
  CharacterCreationFailure.connection,
);

CharacterCreationState _loadedState({CharacterDraft? draft}) =>
    CharacterCreationState(
      draft: draft ?? const CharacterDraft(),
      raceTraits: testRaceTraits,
      raceTraitsStatus: RaceTraitsStatus.loaded,
    );

const _validDraft = CharacterDraft(
  sex: SexType.female,
  name: 'Elara',
  pronoun: PronounType.she,
  race: RaceType.elf,
  classType: ClassType.wizard,
  ageText: '120',
);

const _uploadedA = UploadedPortrait(
  localPath: '/tmp/a.jpg',
  url: 'https://cdn/a.jpg',
);

CharacterCreationState _submittable({
  String? portraitPath,
  UploadedPortrait? uploadedPortrait,
  CharacterCreationFailure? submitFailure,
}) => CharacterCreationState(
  draft: _validDraft,
  raceTraits: testRaceTraits,
  raceTraitsStatus: RaceTraitsStatus.loaded,
  portraitPath: portraitPath,
  uploadedPortrait: uploadedPortrait,
  submitFailure: submitFailure,
);

void main() {
  late MockCharacterCreationRepository repository;

  setUpAll(() {
    registerFallbackValue(PortraitSource.gallery);
    registerFallbackValue(_validDraft.toRequest());
  });

  setUp(() => repository = MockCharacterCreationRepository());

  CharacterCreationCubit build() => CharacterCreationCubit(repository);

  group('editing', () {
    test('initial state is empty, loading and not submittable', () {
      final state = build().state;

      expect(state.draft, const CharacterDraft());
      expect(state.raceTraits, isEmpty);
      expect(state.raceTraitsStatus, RaceTraitsStatus.loading);
      expect(state.portraitPath, isNull);
      expect(state.isSubmitting, isFalse);
      expect(state.submitFailure, isNull);
      expect(state.createdUser, isNull);
      expect(state.canSubmit, isFalse);
    });

    group('loadRaceTraits', () {
      blocTest<CharacterCreationCubit, CharacterCreationState>(
        'emits loading then loaded with the backend traits',
        build: () {
          when(
            () => repository.loadRaceTraits(),
          ).thenAnswer((_) async => testRaceTraits);
          return build();
        },
        seed: () => const CharacterCreationState(),
        act: (cubit) => cubit.loadRaceTraits(),
        expect: () => [_loadedState()],
        verify: (cubit) => expect(cubit.state.raceTraits, testRaceTraits),
      );

      blocTest<CharacterCreationCubit, CharacterCreationState>(
        'emits failed on a typed failure and retries to loaded',
        build: () {
          var calls = 0;
          when(() => repository.loadRaceTraits()).thenAnswer((_) async {
            if (calls++ == 0) throw _connectionError;
            return testRaceTraits;
          });
          return build();
        },
        seed: () => const CharacterCreationState(),
        act: (cubit) async {
          await cubit.loadRaceTraits();
          await cubit.loadRaceTraits();
        },
        expect: () => [
          const CharacterCreationState(
            raceTraitsStatus: RaceTraitsStatus.failed,
          ),
          const CharacterCreationState(
            raceTraitsStatus: RaceTraitsStatus.loading,
          ),
          _loadedState(),
        ],
      );

      blocTest<CharacterCreationCubit, CharacterCreationState>(
        'emits failed on an unexpected error instead of staying in loading',
        build: () {
          when(
            () => repository.loadRaceTraits(),
          ).thenAnswer((_) async => throw StateError('boom'));
          return build();
        },
        seed: () => const CharacterCreationState(),
        act: (cubit) => cubit.loadRaceTraits(),
        expect: () => [
          const CharacterCreationState(
            raceTraitsStatus: RaceTraitsStatus.failed,
          ),
        ],
      );
    });

    group('field edits', () {
      blocTest<CharacterCreationCubit, CharacterCreationState>(
        'each edit emits one state with the draft updated',
        build: build,
        act: (cubit) {
          cubit
            ..selectSex(SexType.female)
            ..updateName('Aria')
            ..selectPronoun(PronounType.she)
            ..selectRace(RaceType.elf)
            ..selectClass(ClassType.wizard)
            ..updateAge('120')
            ..updateBackground('Storia');
        },
        expect: () => [
          isA<CharacterCreationState>().having(
            (s) => s.draft.sex,
            'sex',
            SexType.female,
          ),
          isA<CharacterCreationState>().having(
            (s) => s.draft.name,
            'name',
            'Aria',
          ),
          isA<CharacterCreationState>().having(
            (s) => s.draft.pronoun,
            'pronoun',
            PronounType.she,
          ),
          isA<CharacterCreationState>().having(
            (s) => s.draft.race,
            'race',
            RaceType.elf,
          ),
          isA<CharacterCreationState>().having(
            (s) => s.draft.classType,
            'class',
            ClassType.wizard,
          ),
          isA<CharacterCreationState>().having(
            (s) => s.draft.ageText,
            'age',
            '120',
          ),
          isA<CharacterCreationState>().having(
            (s) => s.draft.background,
            'background',
            'Storia',
          ),
        ],
      );

      blocTest<CharacterCreationCubit, CharacterCreationState>(
        'an edit clears the previous submit failure',
        build: build,
        seed: () => const CharacterCreationState(
          submitFailure: CharacterCreationFailure.nameTaken,
        ),
        act: (cubit) => cubit.updateName('Nuovo'),
        expect: () => [
          isA<CharacterCreationState>()
              .having((s) => s.submitFailure, 'failure', isNull)
              .having((s) => s.draft.name, 'name', 'Nuovo'),
        ],
      );

      blocTest<CharacterCreationCubit, CharacterCreationState>(
        'edits are ignored while submitting (D-05)',
        build: build,
        seed: () => const CharacterCreationState(isSubmitting: true),
        act: (cubit) async {
          cubit
            ..updateName('Aria')
            ..selectRace(RaceType.elf);
          await cubit.pickPortrait(PortraitSource.gallery);
          cubit.removePortrait();
        },
        expect: () => <CharacterCreationState>[],
        verify: (_) => verifyNever(() => repository.pickPortrait(any())),
      );
    });

    group('age gating', () {
      test('is disabled without race, while failed, enabled with traits', () {
        const noRace = CharacterCreationState();
        final raceNoTraits = const CharacterCreationState(
          draft: CharacterDraft(race: RaceType.elf),
          raceTraitsStatus: RaceTraitsStatus.failed,
        );
        final ready = _loadedState(
          draft: const CharacterDraft(race: RaceType.elf),
        );

        expect(noRace.isAgeEnabled, isFalse);
        expect(raceNoTraits.isAgeEnabled, isFalse);
        expect(ready.isAgeEnabled, isTrue);
      });

      blocTest<CharacterCreationCubit, CharacterCreationState>(
        'a race change re-validates the typed age without clamping (D-10)',
        build: build,
        seed: () => _loadedState(
          draft: const CharacterDraft(race: RaceType.elf, ageText: '30'),
        ),
        act: (cubit) => cubit.selectRace(RaceType.human),
        verify: (cubit) {
          expect(cubit.state.draft.ageText, '30');
          expect(cubit.state.ageError, isNull);
        },
      );

      test('elf with age 30 is out of range', () {
        final state = _loadedState(
          draft: const CharacterDraft(race: RaceType.elf, ageText: '30'),
        );

        expect(state.ageError, AgeError.outOfRange);
      });
    });

    test('canSubmit is true only for a draft complete for the traits', () {
      const complete = CharacterDraft(
        sex: SexType.male,
        name: 'Aldo',
        pronoun: PronounType.he,
        race: RaceType.human,
        classType: ClassType.fighter,
        ageText: '30',
      );

      expect(_loadedState().canSubmit, isFalse);
      expect(_loadedState(draft: complete).canSubmit, isTrue);
    });

    group('portrait', () {
      blocTest<CharacterCreationCubit, CharacterCreationState>(
        'pick keeps the file local and never uploads (D-16)',
        build: () {
          when(
            () => repository.pickPortrait(PortraitSource.gallery),
          ).thenAnswer((_) async => '/tmp/p.jpg');
          return build();
        },
        seed: () => const CharacterCreationState(),
        act: (cubit) => cubit.pickPortrait(PortraitSource.gallery),
        expect: () => [
          const CharacterCreationState(portraitPath: '/tmp/p.jpg'),
        ],
        verify: (cubit) {
          expect(cubit.state.pickFailure, isNull);
          verifyNever(() => repository.uploadPortrait(any()));
        },
      );

      blocTest<CharacterCreationCubit, CharacterCreationState>(
        'cancel changes nothing but a previous pick failure',
        build: () {
          when(
            () => repository.pickPortrait(any()),
          ).thenAnswer((_) async => null);
          return build();
        },
        seed: () => const CharacterCreationState(
          portraitPath: '/tmp/old.jpg',
          pickFailure: PortraitPickFailure.permissionDenied,
        ),
        act: (cubit) => cubit.pickPortrait(PortraitSource.camera),
        expect: () => [
          const CharacterCreationState(portraitPath: '/tmp/old.jpg'),
        ],
      );

      blocTest<CharacterCreationCubit, CharacterCreationState>(
        'permission denial surfaces a typed failure and keeps the path',
        build: () {
          when(() => repository.pickPortrait(any())).thenAnswer(
            (_) async => throw const PortraitPickException(
              PortraitPickFailure.permissionDenied,
            ),
          );
          return build();
        },
        seed: () => const CharacterCreationState(portraitPath: '/tmp/old.jpg'),
        act: (cubit) => cubit.pickPortrait(PortraitSource.camera),
        expect: () => [
          const CharacterCreationState(
            portraitPath: '/tmp/old.jpg',
            pickFailure: PortraitPickFailure.permissionDenied,
          ),
        ],
      );

      blocTest<CharacterCreationCubit, CharacterCreationState>(
        'removePortrait clears the path and the uploaded url',
        build: build,
        seed: () => const CharacterCreationState(
          portraitPath: '/tmp/p.jpg',
          uploadedPortrait: UploadedPortrait(
            localPath: '/tmp/p.jpg',
            url: 'https://u',
          ),
        ),
        act: (cubit) => cubit.removePortrait(),
        expect: () => [const CharacterCreationState()],
      );
    });
  });
  group('submit', () {
    final createdUser = buildTestUserWithCharacter();

    void stubCreate() => when(
      () => repository.createCharacter(any()),
    ).thenAnswer((_) async => createdUser);

    void stubCreateFailure(CharacterCreationFailure failure) => when(
      () => repository.createCharacter(any()),
    ).thenAnswer((_) async => throw CharacterCreationException(failure));

    blocTest<CharacterCreationCubit, CharacterCreationState>(
      'does nothing when the form is not submittable',
      build: build,
      seed: () => const CharacterCreationState(),
      act: (cubit) => cubit.submit(),
      expect: () => <CharacterCreationState>[],
      verify: (_) {
        verifyNever(() => repository.uploadPortrait(any()));
        verifyNever(() => repository.createCharacter(any()));
      },
    );

    blocTest<CharacterCreationCubit, CharacterCreationState>(
      'without a portrait sends the mutation without imagePath',
      build: () {
        stubCreate();
        return build();
      },
      seed: _submittable,
      act: (cubit) => cubit.submit(),
      expect: () => [
        _submittable().copyWith(isSubmitting: true),
        _submittable().copyWith(isSubmitting: true, createdUser: createdUser),
      ],
      verify: (_) {
        verifyNever(() => repository.uploadPortrait(any()));
        verify(
          () => repository.createCharacter(_validDraft.toRequest()),
        ).called(1);
      },
    );

    blocTest<CharacterCreationCubit, CharacterCreationState>(
      'uploads the portrait first and sends the returned url',
      build: () {
        when(
          () => repository.uploadPortrait('/tmp/a.jpg'),
        ).thenAnswer((_) async => 'https://cdn/a.jpg');
        stubCreate();
        return build();
      },
      seed: () => _submittable(portraitPath: '/tmp/a.jpg'),
      act: (cubit) => cubit.submit(),
      expect: () {
        final submitting = _submittable(
          portraitPath: '/tmp/a.jpg',
        ).copyWith(isSubmitting: true);
        final uploaded = submitting.copyWith(uploadedPortrait: _uploadedA);
        return [
          submitting,
          uploaded,
          uploaded.copyWith(createdUser: createdUser),
        ];
      },
      verify: (_) {
        verifyInOrder([
          () => repository.uploadPortrait('/tmp/a.jpg'),
          () => repository.createCharacter(
            _validDraft.toRequest(imagePath: 'https://cdn/a.jpg'),
          ),
        ]);
      },
    );

    blocTest<CharacterCreationCubit, CharacterCreationState>(
      'upload failure stops the flow and preserves the data',
      build: () {
        when(() => repository.uploadPortrait(any())).thenAnswer(
          (_) async => throw const CharacterCreationException(
            CharacterCreationFailure.uploadFailed,
          ),
        );
        return build();
      },
      seed: () => _submittable(portraitPath: '/tmp/a.jpg'),
      act: (cubit) => cubit.submit(),
      expect: () => [
        _submittable(portraitPath: '/tmp/a.jpg').copyWith(isSubmitting: true),
        _submittable(
          portraitPath: '/tmp/a.jpg',
          submitFailure: CharacterCreationFailure.uploadFailed,
        ),
      ],
      verify: (cubit) {
        verifyNever(() => repository.createCharacter(any()));
        expect(cubit.state.draft, _validDraft);
        expect(cubit.state.portraitPath, '/tmp/a.jpg');
      },
    );

    blocTest<CharacterCreationCubit, CharacterCreationState>(
      'mutation failure after the upload keeps the uploaded url',
      build: () {
        when(
          () => repository.uploadPortrait(any()),
        ).thenAnswer((_) async => 'https://cdn/a.jpg');
        stubCreateFailure(CharacterCreationFailure.nameTaken);
        return build();
      },
      seed: () => _submittable(portraitPath: '/tmp/a.jpg'),
      act: (cubit) => cubit.submit(),
      verify: (cubit) {
        expect(cubit.state.isSubmitting, isFalse);
        expect(cubit.state.submitFailure, CharacterCreationFailure.nameTaken);
        expect(cubit.state.uploadedPortrait, _uploadedA);
        expect(cubit.state.createdUser, isNull);
      },
    );

    blocTest<CharacterCreationCubit, CharacterCreationState>(
      'retry with the same photo skips the upload',
      build: () {
        stubCreate();
        return build();
      },
      seed: () => _submittable(
        portraitPath: '/tmp/a.jpg',
        uploadedPortrait: _uploadedA,
        submitFailure: CharacterCreationFailure.nameTaken,
      ),
      act: (cubit) => cubit.submit(),
      verify: (_) {
        verifyNever(() => repository.uploadPortrait(any()));
        verify(
          () => repository.createCharacter(
            _validDraft.toRequest(imagePath: 'https://cdn/a.jpg'),
          ),
        ).called(1);
      },
    );

    blocTest<CharacterCreationCubit, CharacterCreationState>(
      'a different photo forces a new upload',
      build: () {
        when(
          () => repository.uploadPortrait('/tmp/b.jpg'),
        ).thenAnswer((_) async => 'https://cdn/b.jpg');
        stubCreate();
        return build();
      },
      seed: () => _submittable(
        portraitPath: '/tmp/b.jpg',
        uploadedPortrait: _uploadedA,
      ),
      act: (cubit) => cubit.submit(),
      verify: (_) {
        verify(() => repository.uploadPortrait('/tmp/b.jpg')).called(1);
        verify(
          () => repository.createCharacter(
            _validDraft.toRequest(imagePath: 'https://cdn/b.jpg'),
          ),
        ).called(1);
      },
    );

    blocTest<CharacterCreationCubit, CharacterCreationState>(
      'starting a submit clears the previous failure',
      build: () {
        stubCreate();
        return build();
      },
      seed: () =>
          _submittable(submitFailure: CharacterCreationFailure.connection),
      act: (cubit) => cubit.submit(),
      expect: () => [
        _submittable().copyWith(isSubmitting: true),
        _submittable().copyWith(isSubmitting: true, createdUser: createdUser),
      ],
    );

    blocTest<CharacterCreationCubit, CharacterCreationState>(
      'an unexpected error ends in unknown without a stuck spinner',
      build: () {
        when(
          () => repository.createCharacter(any()),
        ).thenAnswer((_) async => throw StateError('boom'));
        return build();
      },
      seed: _submittable,
      act: (cubit) => cubit.submit(),
      verify: (cubit) {
        expect(cubit.state.isSubmitting, isFalse);
        expect(cubit.state.submitFailure, CharacterCreationFailure.unknown);
      },
    );

    blocTest<CharacterCreationCubit, CharacterCreationState>(
      'on success the form stays locked and cannot be submitted again',
      build: () {
        stubCreate();
        return build();
      },
      seed: _submittable,
      act: (cubit) => cubit.submit(),
      verify: (cubit) {
        expect(cubit.state.isSubmitting, isTrue);
        expect(cubit.state.canSubmit, isFalse);
      },
    );

    test(
      'canExit is false only while a submit is in flight without a user',
      () {
        expect(_submittable().canExit, isTrue);
        expect(_submittable().copyWith(isSubmitting: true).canExit, isFalse);
        expect(
          _submittable()
              .copyWith(isSubmitting: true, createdUser: createdUser)
              .canExit,
          isTrue,
        );
      },
    );

    blocTest<CharacterCreationCubit, CharacterCreationState>(
      'a refused handover unlocks the sheet and names the cause (D-29)',
      build: build,
      seed: () =>
          _submittable().copyWith(isSubmitting: true, createdUser: createdUser),
      act: (cubit) => cubit.handoverRejected(),
      expect: () => [
        _submittable(submitFailure: CharacterCreationFailure.handoverRejected),
      ],
      verify: (cubit) => expect(cubit.state.canExit, isTrue),
    );
    blocTest<CharacterCreationCubit, CharacterCreationState>(
      'alreadyExists adopts the character re-read from me',
      build: () {
        stubCreateFailure(CharacterCreationFailure.alreadyExists);
        when(
          () => repository.fetchCurrentUser(),
        ).thenAnswer((_) async => createdUser);
        return build();
      },
      seed: _submittable,
      act: (cubit) => cubit.submit(),
      verify: (cubit) {
        expect(cubit.state.createdUser?.currentCharacter?.id, testCharacterId);
        expect(cubit.state.isSubmitting, isTrue);
        expect(cubit.state.submitFailure, isNull);
      },
    );

    blocTest<CharacterCreationCubit, CharacterCreationState>(
      'alreadyExists without a character on me shows the notice',
      build: () {
        stubCreateFailure(CharacterCreationFailure.alreadyExists);
        when(
          () => repository.fetchCurrentUser(),
        ).thenAnswer((_) async => buildTestUser());
        return build();
      },
      seed: _submittable,
      act: (cubit) => cubit.submit(),
      verify: (cubit) {
        expect(cubit.state.isSubmitting, isFalse);
        expect(
          cubit.state.submitFailure,
          CharacterCreationFailure.alreadyExists,
        );
        expect(cubit.state.createdUser, isNull);
      },
    );

    blocTest<CharacterCreationCubit, CharacterCreationState>(
      'alreadyExists with a failing re-read shows the notice',
      build: () {
        stubCreateFailure(CharacterCreationFailure.alreadyExists);
        when(
          () => repository.fetchCurrentUser(),
        ).thenAnswer((_) async => throw _connectionError);
        return build();
      },
      seed: _submittable,
      act: (cubit) => cubit.submit(),
      verify: (cubit) {
        expect(cubit.state.isSubmitting, isFalse);
        expect(
          cubit.state.submitFailure,
          CharacterCreationFailure.alreadyExists,
        );
      },
    );

    blocTest<CharacterCreationCubit, CharacterCreationState>(
      'alreadyExists with an unexpected re-read error never leaves the spinner',
      build: () {
        stubCreateFailure(CharacterCreationFailure.alreadyExists);
        when(
          () => repository.fetchCurrentUser(),
        ).thenAnswer((_) async => throw StateError('boom'));
        return build();
      },
      seed: _submittable,
      act: (cubit) => cubit.submit(),
      errors: () => isEmpty,
      verify: (cubit) {
        expect(cubit.state.isSubmitting, isFalse);
        expect(
          cubit.state.submitFailure,
          CharacterCreationFailure.alreadyExists,
        );
      },
    );

    for (final failure in [
      CharacterCreationFailure.nameTaken,
      CharacterCreationFailure.connection,
      CharacterCreationFailure.startingLocationUnavailable,
    ]) {
      blocTest<CharacterCreationCubit, CharacterCreationState>(
        '$failure does not re-read me',
        build: () {
          stubCreateFailure(failure);
          return build();
        },
        seed: _submittable,
        act: (cubit) => cubit.submit(),
        verify: (cubit) {
          verifyNever(() => repository.fetchCurrentUser());
          expect(cubit.state.submitFailure, failure);
          expect(cubit.state.isSubmitting, isFalse);
        },
      );
    }

    blocTest<CharacterCreationCubit, CharacterCreationState>(
      'a response arriving after close is harmless',
      build: build,
      seed: _submittable,
      act: (cubit) async {
        final completer = Completer<User>();
        when(
          () => repository.createCharacter(any()),
        ).thenAnswer((_) => completer.future);
        final future = cubit.submit();
        await cubit.close();
        completer.complete(createdUser);
        await future;
      },
      expect: () => [_submittable().copyWith(isSubmitting: true)],
      errors: () => isEmpty,
    );
  });
}
