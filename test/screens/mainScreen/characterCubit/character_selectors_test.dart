import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/character/character.dart';
import 'package:klimmeck_guide/models/character/character_status.dart';
import 'package:klimmeck_guide/models/enums/injury_type.dart';
import 'package:klimmeck_guide/screens/mainScreen/characterCubit/character_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/characterCubit/character_selectors.dart';

CharacterLoaded _loaded({
  required List<String> injuries,
  List<String>? innkeeperInjuries,
}) => CharacterLoaded(
  Character.fromJson({
    'id': 'c-1',
    'status': {'injuries': injuries, 'innkeeperInjuries': ?innkeeperInjuries},
  }),
);

void main() {
  test('curableInjuriesOf leaves the innkeeper wounds out (D-14)', () {
    final state = _loaded(
      injuries: const ['contusion', 'blackEye'],
      innkeeperInjuries: const ['blackEye'],
    );

    expect(curableInjuriesOf(state), [InjuryType.contusion]);
  });

  test('every wound is curable without innkeeper wounds (D-19)', () {
    final state = _loaded(injuries: const ['contusion', 'blackEye']);

    expect(curableInjuriesOf(state), [
      InjuryType.contusion,
      InjuryType.blackEye,
    ]);
  });

  test('null without a character', () {
    expect(curableInjuriesOf(CharacterInitial()), isNull);
  });

  group('woundsOf (IN-03)', () {
    test('gives the wounds and, among them, the innkeeper ones (D-18)', () {
      final state = _loaded(
        injuries: const ['contusion', 'blackEye'],
        innkeeperInjuries: const ['blackEye'],
      );

      final wounds = woundsOf(state)!;

      expect(wounds.injuries, [InjuryType.contusion, InjuryType.blackEye]);
      expect(wounds.innkeeperInjuries, [InjuryType.blackEye]);
    });

    test('null without a character', () {
      expect(woundsOf(CharacterInitial()), isNull);
    });

    test('null for a character served without status', () {
      final state = CharacterLoaded(Character.fromJson(const {'id': 'c-1'}));

      expect(woundsOf(state), isNull);
    });

    test('no wounds for a status served without the list', () {
      const state = CharacterLoaded(
        Character(
          id: 'c-1',
          infos: null,
          quests: null,
          assets: null,
          status: CharacterStatus(
            location: null,
            xp: null,
            coins: null,
            injuries: null,
            currentLifePoints: null,
            maxLifePoints: null,
            title: null,
            level: null,
            maxActiveSpells: null,
          ),
        ),
      );

      final wounds = woundsOf(state)!;

      expect(wounds.injuries, isEmpty);
      expect(wounds.innkeeperInjuries, isEmpty);
    });
  });
}
