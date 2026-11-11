import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/base_damage.dart';
import 'package:klimmeck_guide/models/energy_damage.dart';
import 'package:klimmeck_guide/models/enums/damage_type.dart';
import 'package:klimmeck_guide/models/enums/energy_type.dart';
import 'package:klimmeck_guide/models/enums/rarity_type.dart';
import 'package:klimmeck_guide/models/pet.dart';

import '../helpers/fixtures/shop_fixtures.dart';

void main() {
  group('Pet', () {
    test('parses speedModifier as a double from an int or a float (D-11)', () {
      expect(Pet.fromJson(petJson(speedModifier: 2)).speedModifier, 2.0);
      expect(Pet.fromJson(petJson(speedModifier: 2.5)).speedModifier, 2.5);
    });

    test(
      'leaves speedModifier null for a companion that is not a mount (D-07)',
      () {
        expect(Pet.fromJson(catPetJson()).speedModifier, isNull);
      },
    );

    test('parses sellable from the wire (D-09)', () {
      expect(Pet.fromJson(petJson(sellable: true)).sellable, isTrue);
      expect(Pet.fromJson(petJson(sellable: false)).sellable, isFalse);
      expect(Pet.fromJson(petJson()..remove('sellable')).sellable, isNull);
    });

    test('lists speedModifier and sellable in props', () {
      expect(
        Pet.fromJson(petJson(speedModifier: 2)),
        isNot(Pet.fromJson(petJson(speedModifier: 2.5))),
      );
      expect(
        Pet.fromJson(petJson(sellable: true)),
        isNot(Pet.fromJson(petJson(sellable: false))),
      );
    });
  });

  group('Pet.tryFromJson', () {
    test('parses a map that carries a string id (D-06, D-07)', () {
      expect(Pet.tryFromJson(petJson()), Pet.fromJson(petJson()));
    });

    test('returns null for a value that is not a map (D-06, D-07)', () {
      expect(Pet.tryFromJson(null), isNull);
      expect(Pet.tryFromJson('pet-travel-horse'), isNull);
    });

    test('returns null for a map without a string id (D-06, D-07)', () {
      expect(Pet.tryFromJson(petJson()..remove('id')), isNull);
      expect(Pet.tryFromJson(petJson()..['id'] = 7), isNull);
    });
  });

  group('attack and defense (Phase 19)', () {
    Map<String, dynamic> attackJson() => {
      'base': [
        {'type': 'cut', 'power': 12},
      ],
      'energy': [
        {'type': 'fire', 'power': 5},
      ],
    };
    Map<String, dynamic> defenseJson() => {
      'base': [
        {'type': 'blunt', 'power': 4},
      ],
      'energy': <Map<String, dynamic>>[],
    };

    test('parses attack and defense as damages (D-12)', () {
      final pet = Pet.fromJson(
        petJson(attack: attackJson(), defense: defenseJson()),
      );

      expect(pet.attack?.base, const [
        BaseDamage(type: DamageType.cut, power: 12),
      ]);
      expect(pet.attack?.energy, const [
        EnergyDamage(type: EnergyType.fire, power: 5),
      ]);
      expect(pet.defense?.base, const [
        BaseDamage(type: DamageType.blunt, power: 4),
      ]);
      expect(pet.defense?.energy, isEmpty);
    });

    test('a pet without attack and defense has both null (D-12)', () {
      final pet = Pet.fromJson(petJson());

      expect(pet.attack, isNull);
      expect(pet.defense, isNull);
    });

    test('an attack that is not a map is null (D-12)', () {
      final pet = Pet.fromJson({...petJson(), 'attack': 'bite'});

      expect(pet.attack, isNull);
      expect(pet.name, 'Cavallo da viaggio');
    });

    test('a non-map attack is null (D-16)', () {
      expect(Pet.tryFromJson({...petJson(), 'attack': 7})?.attack, isNull);
      expect(
        Pet.tryFromJson({
          ...petJson(),
          'attack': [attackJson()],
        })?.id,
        'pet-travel-horse',
      );
    });

    test('a non-map defense is null (D-16)', () {
      expect(
        Pet.tryFromJson({...petJson(), 'defense': 'hide'})?.defense,
        isNull,
      );
      expect(
        Pet.tryFromJson({
          ...petJson(),
          'defense': [defenseJson()],
        })?.id,
        'pet-travel-horse',
      );
    });

    test('drops an attack entry with an unknown type (D-12, D-16)', () {
      final pet = Pet.fromJson(
        petJson(
          attack: {
            'base': [
              {'type': 'cut', 'power': 12},
              {'type': 'gnaw', 'power': 3},
            ],
            'energy': [
              {'type': 'void', 'power': 9},
            ],
          },
        ),
      );

      expect(pet.attack?.base, const [
        BaseDamage(type: DamageType.cut, power: 12),
      ]);
      expect(pet.attack?.energy, isEmpty);
    });

    test('parses maxXp from the wire (D-03)', () {
      expect(Pet.fromJson(petJson(maxXp: 300)).maxXp, 300);
      expect(Pet.fromJson(petJson()).maxXp, isNull);
    });

    test('toJson writes attack, defense and maxXp and none of the '
        'per-character fields (D-03, D-12)', () {
      final json = Pet.fromJson(
        petJson(maxXp: 300, attack: attackJson(), defense: defenseJson()),
      ).toJson();

      expect(json['attack'], attackJson());
      expect(json['defense'], defenseJson());
      expect(json['maxXp'], 300);
      expect(json.keys, isNot(contains('xp')));
      expect(json.keys, isNot(contains('currentLifePoints')));
      expect(json.keys, isNot(contains('damages')));
    });

    test('attack and defense are part of the props (D-12)', () {
      expect(
        Pet.fromJson(petJson(attack: attackJson())),
        isNot(Pet.fromJson(petJson())),
      );
      expect(
        Pet.fromJson(petJson(defense: defenseJson())),
        isNot(Pet.fromJson(petJson())),
      );
    });

    test('parses a known rarity (D-20)', () {
      expect(Pet.fromJson(petJson(rarity: 'rare')).rarity, RarityType.rare);
    });

    test('unknown rarity is null (D-20)', () {
      final pet = Pet.fromJson(petJson(rarity: 'mythic'));

      expect(pet.rarity, isNull);
      expect(pet.name, 'Cavallo da viaggio');
    });

    test('a missing or non-string rarity is null (D-20)', () {
      expect(Pet.fromJson(petJson()).rarity, isNull);
      expect(Pet.fromJson({...petJson(), 'rarity': 3}).rarity, isNull);
    });

    test('toJson writes the rarity name and the rarity is part of the '
        'props (D-20)', () {
      expect(Pet.fromJson(petJson(rarity: 'rare')).toJson()['rarity'], 'rare');
      expect(
        Pet.fromJson(petJson(rarity: 'rare')),
        isNot(Pet.fromJson(petJson(rarity: 'common'))),
      );
    });
  });
}
