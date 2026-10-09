import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/enums/class_type.dart';
import 'package:klimmeck_guide/models/enums/pronoun_type.dart';
import 'package:klimmeck_guide/models/enums/race_type.dart';
import 'package:klimmeck_guide/models/enums/sex_type.dart';
import 'package:klimmeck_guide/repository/character_creation_failure.dart';
import 'package:klimmeck_guide/repository/services/image/portrait_picker.dart';
import 'package:klimmeck_guide/screens/characterCreation/cubit/character_creation_cubit.dart';
import 'package:klimmeck_guide/screens/characterCreation/cubit/character_draft.dart';
import 'package:mocktail/mocktail.dart';

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

void main() {
  late MockCharacterCreationRepository repository;

  setUpAll(() => registerFallbackValue(PortraitSource.gallery));

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
}
