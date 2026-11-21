import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/character/character.dart';
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
}
