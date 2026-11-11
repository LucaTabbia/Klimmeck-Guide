import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/enums/energy_type.dart';
import 'package:klimmeck_guide/models/spell.dart';

import '../helpers/fixtures/spell_fixtures.dart';

void main() {
  group('Spell.fromJson energy damage', () {
    test('parses a known energy damage (D-16)', () {
      final spell = Spell.fromJson(spellJson());

      expect(spell.energyDamage!.type, EnergyType.fire);
      expect(spell.energyDamage!.power, 12);
    });

    test(
      'an unknown energy type leaves the spell without energy damage (D-16)',
      () {
        final spell = Spell.fromJson(spellJson(energy: 'plasma'));

        expect(spell.energyDamage, isNull);
        expect(spell.name, 'Dardo di fuoco');
      },
    );

    test('an energy damage that is not a map is null (D-16)', () {
      final spell = Spell.fromJson({...spellJson(), 'energyDamage': 'fire'});

      expect(spell.energyDamage, isNull);
      expect(spell.name, 'Dardo di fuoco');
    });
  });
}
