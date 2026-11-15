import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/enums/energy_type.dart';
import 'package:klimmeck_guide/models/enums/spell_origin.dart';
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

  group('origin and minimum level (BE Phase 24)', () {
    test('reads the origin and the minimum level as served (D-01, D-07)', () {
      final spell = Spell.fromJson(
        spellJson(origin: 'void', minLevelToLearn: 6),
      );

      expect(spell.origin, SpellOrigin.theVoid);
      expect(spell.minLevelToLearn, 6);
    });

    test('an absent, unknown or malformed origin reads null and keeps the '
        'spell (D-01)', () {
      for (final json in [
        spellJson(),
        spellJson(origin: 'chaos'),
        spellJson(origin: 7),
      ]) {
        final spell = Spell.fromJson(json);

        expect(spell.origin, isNull, reason: '${json['origin']}');
        expect(spell.name, 'Dardo di fuoco');
      }
    });

    test('an absent or malformed minimum level reads null and keeps the '
        'spell (D-07)', () {
      for (final json in [spellJson(), spellJson(minLevelToLearn: '6')]) {
        final spell = Spell.fromJson(json);

        expect(spell.minLevelToLearn, isNull);
        expect(spell.name, 'Dardo di fuoco');
      }
      expect(
        Spell.fromJson(spellJson(minLevelToLearn: 6.0)).minLevelToLearn,
        6,
      );
    });

    test('toJson writes the wire name of the origin and the level, never '
        'minXpToLearn (D-01, D-07)', () {
      final json = Spell.fromJson(
        spellJson(origin: 'void', minLevelToLearn: 6),
      ).toJson();

      expect(json['origin'], 'void');
      expect(json['minLevelToLearn'], 6);
      expect(json.containsKey('minXpToLearn'), isFalse);
    });

    test('props and copyWith carry origin and minimum level (D-01, D-07)', () {
      final spell = Spell.fromJson(spellJson());
      final copy = spell.copyWith(
        origin: SpellOrigin.shamanic,
        minLevelToLearn: 4,
      );

      expect(copy.origin, SpellOrigin.shamanic);
      expect(copy.minLevelToLearn, 4);
      expect(copy, isNot(spell));
      expect(spell.copyWith(origin: SpellOrigin.arcane), isNot(spell));
      expect(spell.copyWith(minLevelToLearn: 4), isNot(spell));
      expect(copy.copyWith(), copy);
    });
  });
}
