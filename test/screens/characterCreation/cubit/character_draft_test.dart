import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/enums/class_type.dart';
import 'package:klimmeck_guide/models/enums/pronoun_type.dart';
import 'package:klimmeck_guide/models/enums/race_type.dart';
import 'package:klimmeck_guide/models/enums/sex_type.dart';
import 'package:klimmeck_guide/models/request/create_character_request.dart';
import 'package:klimmeck_guide/screens/characterCreation/cubit/character_draft.dart';

import '../../../helpers/fixtures/race_traits_fixture.dart';

CharacterDraft draftNamed(String name) => CharacterDraft(name: name);

CharacterDraft completeDraft() => const CharacterDraft(
  sex: SexType.female,
  name: 'Aria',
  pronoun: PronounType.she,
  race: RaceType.elf,
  classType: ClassType.wizard,
  ageText: '120',
);

void main() {
  group('name', () {
    test('empty is required', () {
      expect(draftNamed('').nameError, NameError.required);
      expect(draftNamed('   ').nameError, NameError.required);
    });

    test('a single letter is too short', () {
      expect(draftNamed('  A ').nameError, NameError.tooShort);
    });

    test('21 letters are too long, 20 are fine', () {
      expect(draftNamed('a' * 21).nameError, NameError.tooLong);
      expect(draftNamed('a' * 20).nameError, isNull);
    });

    test('digits and punctuation are invalid characters', () {
      expect(draftNamed('Aria2').nameError, NameError.invalidCharacters);
      expect(draftNamed('Aria!').nameError, NameError.invalidCharacters);
    });

    test('a name without any letter is invalid', () {
      expect(draftNamed('--').nameError, NameError.invalidCharacters);
      expect(draftNamed("' '").nameError, NameError.invalidCharacters);
    });

    test('apostrophes, hyphens and accents are accepted', () {
      for (final name in ["D'Arcy", 'D’Arcy', 'Jean-Luc', 'Élodie', 'Zoë']) {
        expect(draftNamed(name).nameError, isNull, reason: name);
      }
    });

    test('whitespace is trimmed and collapsed', () {
      final draft = draftNamed('  Anna   Maria ');

      expect(draft.normalizedName, 'Anna Maria');
      expect(draft.nameError, isNull);
    });

    test('length counts UTF-16 units of the normalized name', () {
      expect(draftNamed('é' * 20).nameError, isNull);
      expect(draftNamed('é' * 21).nameError, NameError.tooLong);
    });
  });

  group('age', () {
    final elf = testRaceTraits[RaceType.elf];
    final human = testRaceTraits[RaceType.human];

    test(
      'without a race there is no age error and the draft is incomplete',
      () {
        const draft = CharacterDraft(ageText: '30');

        expect(draft.ageErrorFor(null), isNull);
        expect(draft.isCompleteFor(testRaceTraits), isFalse);
      },
    );

    test('empty text is required', () {
      expect(const CharacterDraft().ageErrorFor(elf), AgeError.required);
    });

    test('non numeric text is not a number', () {
      const draft = CharacterDraft(ageText: 'abc');

      expect(draft.ageErrorFor(elf), AgeError.notANumber);
    });

    test('an age outside the race range is out of range', () {
      const draft = CharacterDraft(race: RaceType.elf, ageText: '30');

      expect(draft.ageErrorFor(elf), AgeError.outOfRange);
      expect(draft.ageErrorFor(human), isNull);
    });

    test('changing race re-evaluates the same text without clamping', () {
      const elfDraft = CharacterDraft(race: RaceType.elf, ageText: '30');
      final humanDraft = elfDraft.copyWith(race: RaceType.human);

      expect(elfDraft.ageErrorFor(elf), AgeError.outOfRange);
      expect(humanDraft.ageText, '30');
      expect(humanDraft.ageErrorFor(human), isNull);
    });
  });

  group('background', () {
    test('empty is valid', () {
      expect(const CharacterDraft().isBackgroundTooLong, isFalse);
    });

    test('500 units are valid, 501 are too long', () {
      expect(
        CharacterDraft(background: 'a' * 500).isBackgroundTooLong,
        isFalse,
      );
      expect(CharacterDraft(background: 'a' * 501).isBackgroundTooLong, isTrue);
    });

    test('surrounding whitespace is trimmed before counting', () {
      final draft = CharacterDraft(background: '   ${'a' * 500}   ');

      expect(draft.isBackgroundTooLong, isFalse);
    });
  });

  group('completeness', () {
    test('a fully valid draft is complete', () {
      expect(completeDraft().isCompleteFor(testRaceTraits), isTrue);
    });

    test('each missing pick makes it incomplete', () {
      final draft = completeDraft();
      final incomplete = [
        const CharacterDraft(),
        CharacterDraft(
          name: draft.name,
          pronoun: draft.pronoun,
          race: draft.race,
          classType: draft.classType,
          ageText: draft.ageText,
        ),
        CharacterDraft(
          sex: draft.sex,
          name: draft.name,
          race: draft.race,
          classType: draft.classType,
          ageText: draft.ageText,
        ),
        CharacterDraft(
          sex: draft.sex,
          name: draft.name,
          pronoun: draft.pronoun,
          classType: draft.classType,
          ageText: draft.ageText,
        ),
        CharacterDraft(
          sex: draft.sex,
          name: draft.name,
          pronoun: draft.pronoun,
          race: draft.race,
          ageText: draft.ageText,
        ),
      ];

      for (final candidate in incomplete) {
        expect(candidate.isCompleteFor(testRaceTraits), isFalse);
      }
    });

    test('an invalid name, age or background makes it incomplete', () {
      expect(
        completeDraft().copyWith(name: 'A').isCompleteFor(testRaceTraits),
        isFalse,
      );
      expect(
        completeDraft().copyWith(ageText: '30').isCompleteFor(testRaceTraits),
        isFalse,
      );
      expect(
        completeDraft()
            .copyWith(background: 'a' * 501)
            .isCompleteFor(testRaceTraits),
        isFalse,
      );
    });

    test('a race without traits makes it incomplete', () {
      expect(completeDraft().isCompleteFor(const {}), isFalse);
    });
  });

  test('toRequest builds the normalized request', () {
    final request = completeDraft()
        .copyWith(name: '  Aria   Vale ', background: '  Storia  ')
        .toRequest(imagePath: 'https://x');

    expect(
      request,
      const CreateCharacterRequest(
        name: 'Aria Vale',
        sex: SexType.female,
        pronoun: PronounType.she,
        race: RaceType.elf,
        classType: ClassType.wizard,
        age: 120,
        background: 'Storia',
        imagePath: 'https://x',
      ),
    );
  });
}
