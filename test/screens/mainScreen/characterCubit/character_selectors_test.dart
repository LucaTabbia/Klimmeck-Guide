import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/character/character.dart';
import 'package:klimmeck_guide/models/enums/injury_type.dart';
import 'package:klimmeck_guide/screens/mainScreen/characterCubit/character_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/characterCubit/character_selectors.dart';

void main() {
  test(
    'characterInjuriesOf gives the injuries of a loaded character and null otherwise (D-19)',
    () {
      final loaded = CharacterLoaded(
        Character.fromJson({
          'id': 'c-1',
          'status': {
            'injuries': ['contusion'],
          },
        }),
      );

      expect(characterInjuriesOf(loaded), [InjuryType.contusion]);
      expect(characterInjuriesOf(CharacterInitial()), isNull);
    },
  );
}
