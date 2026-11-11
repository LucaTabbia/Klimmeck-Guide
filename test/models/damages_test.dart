import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/base_damage.dart';
import 'package:klimmeck_guide/models/damages.dart';
import 'package:klimmeck_guide/models/energy_damage.dart';
import 'package:klimmeck_guide/models/enums/damage_type.dart';
import 'package:klimmeck_guide/models/enums/energy_type.dart';

void main() {
  group('Damages.fromJson', () {
    test('parses base and energy entries (D-16)', () {
      final damages = Damages.fromJson({
        'base': [
          {'type': 'cut', 'power': 12},
        ],
        'energy': [
          {'type': 'fire', 'power': 5},
        ],
      });

      expect(damages.base, [const BaseDamage(type: DamageType.cut, power: 12)]);
      expect(damages.energy, [
        const EnergyDamage(type: EnergyType.fire, power: 5),
      ]);
    });

    test(
      'drops a base entry with an unknown type name and keeps the others (D-16)',
      () {
        final damages = Damages.fromJson({
          'base': [
            {'type': 'laser', 'power': 9},
            {'type': 'blunt', 'power': 4},
          ],
        });

        expect(damages.base, [
          const BaseDamage(type: DamageType.blunt, power: 4),
        ]);
      },
    );

    test('drops an energy entry with an unknown type name (D-16)', () {
      final damages = Damages.fromJson({
        'energy': [
          {'type': 'plasma', 'power': 9},
          {'type': 'cold', 'power': 2},
        ],
      });

      expect(damages.energy, [
        const EnergyDamage(type: EnergyType.cold, power: 2),
      ]);
    });

    test('drops an entry without a type (D-16)', () {
      final damages = Damages.fromJson({
        'base': [
          {'power': 3},
        ],
        'energy': [
          {'power': 3},
        ],
      });

      expect(damages.base, isEmpty);
      expect(damages.energy, isEmpty);
    });

    test('drops an entry that is not a map (D-16)', () {
      final damages = Damages.fromJson({
        'base': ['cut', 7, null],
        'energy': ['fire', 7, null],
      });

      expect(damages.base, isEmpty);
      expect(damages.energy, isEmpty);
    });

    test(
      'a base or energy value that is not a list is an empty list (D-16)',
      () {
        final damages = Damages.fromJson({'base': 'cut', 'energy': 3});

        expect(damages.base, isEmpty);
        expect(damages.energy, isEmpty);
      },
    );

    test('an entry without a power keeps its type (D-16)', () {
      final damages = Damages.fromJson({
        'base': [
          {'type': 'cut'},
        ],
      });

      expect(damages.base!.single.type, DamageType.cut);
      expect(damages.base!.single.power, isNull);
    });

    test('every parsed entry has a non-null type (D-16)', () {
      final damages = Damages.fromJson({
        'base': [
          {'type': 'cut', 'power': 1},
          {'type': null, 'power': 2},
          {'type': 'laser', 'power': 3},
          {'type': 7, 'power': 4},
          {'type': 'pierce', 'power': 5},
        ],
        'energy': [
          {'type': null, 'power': 1},
          {'type': 'radiant', 'power': 2},
          {'type': 'plasma', 'power': 3},
        ],
      });

      expect(damages.base!.map((entry) => entry.type), [
        DamageType.cut,
        DamageType.pierce,
      ]);
      expect(damages.energy!.map((entry) => entry.type), [EnergyType.radiant]);
    });
  });

  group('BaseDamage.tryFromJson', () {
    test('parses a known type (D-16)', () {
      expect(
        BaseDamage.tryFromJson({'type': 'pierce', 'power': 6}),
        const BaseDamage(type: DamageType.pierce, power: 6),
      );
    });

    test('an unknown type name is null (D-16)', () {
      expect(BaseDamage.tryFromJson({'type': 'laser', 'power': 6}), isNull);
    });

    test('a missing type is null (D-16)', () {
      expect(BaseDamage.tryFromJson({'power': 6}), isNull);
    });

    test('a value that is not a map is null (D-16)', () {
      expect(BaseDamage.tryFromJson('cut'), isNull);
      expect(BaseDamage.tryFromJson(null), isNull);
    });
  });

  group('EnergyDamage.tryFromJson', () {
    test('parses a known type (D-16)', () {
      expect(
        EnergyDamage.tryFromJson({'type': 'necrotic', 'power': 6}),
        const EnergyDamage(type: EnergyType.necrotic, power: 6),
      );
    });

    test('an unknown type name is null (D-16)', () {
      expect(EnergyDamage.tryFromJson({'type': 'plasma', 'power': 6}), isNull);
    });

    test('a missing type is null (D-16)', () {
      expect(EnergyDamage.tryFromJson({'power': 6}), isNull);
    });

    test('a value that is not a map is null (D-16)', () {
      expect(EnergyDamage.tryFromJson('fire'), isNull);
      expect(EnergyDamage.tryFromJson(null), isNull);
    });
  });
}
