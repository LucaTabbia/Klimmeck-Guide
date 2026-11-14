import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/owned_pet.dart';
import 'package:klimmeck_guide/models/pet.dart';

import '../helpers/fixtures/shop_fixtures.dart';

void main() {
  group('OwnedPet', () {
    test('parses an entry with its catalogue pet, xp and life (D-03)', () {
      final owned = OwnedPet.tryFromJson(
        ownedPetJson(pet: petJson(maxXp: 300), xp: 40, currentLifePoints: 7),
      );

      expect(owned?.pet, Pet.fromJson(petJson(maxXp: 300)));
      expect(owned?.xp, 40);
      expect(owned?.currentLifePoints, 7);
    });

    test('an entry without a readable pet is null (D-03)', () {
      expect(
        OwnedPet.tryFromJson(<String, dynamic>{
          'pet': null,
          'xp': 1,
          'currentLifePoints': 1,
        }),
        isNull,
      );
      expect(
        OwnedPet.tryFromJson(<String, dynamic>{
          'pet': <String, dynamic>{'name': 'senza id'},
          'xp': 1,
          'currentLifePoints': 1,
        }),
        isNull,
      );
    });

    test('a value that is not a map is null (D-03)', () {
      expect(OwnedPet.tryFromJson(null), isNull);
      expect(OwnedPet.tryFromJson('pet-travel-horse'), isNull);
      expect(OwnedPet.tryFromJson([ownedPetJson()]), isNull);
    });

    test('toJson round-trips the entry (D-03)', () {
      final owned = OwnedPet.tryFromJson(
        ownedPetJson(pet: petJson(maxXp: 300), xp: 40, currentLifePoints: 7),
      );

      expect(OwnedPet.tryFromJson(owned?.toJson()), owned);
      expect(owned?.toJson()['xp'], 40);
      expect(owned?.toJson()['currentLifePoints'], 7);
    });

    test('xp and life are part of the props (D-03)', () {
      expect(
        OwnedPet.tryFromJson(ownedPetJson(xp: 40)),
        isNot(OwnedPet.tryFromJson(ownedPetJson(xp: 41))),
      );
      expect(
        OwnedPet.tryFromJson(ownedPetJson(currentLifePoints: 7)),
        isNot(OwnedPet.tryFromJson(ownedPetJson(currentLifePoints: 8))),
      );
    });
  });

  group('entry boundary (Phase 19)', () {
    const malformedFields = <String, Object>{
      'name': 7,
      'buyPrice': 'un oro',
      'sellPrice': [50],
      'maxXp': 'trecento',
      'speedModifier': 'doppia',
    };

    for (final MapEntry(key: field, value: value) in malformedFields.entries) {
      test('an entry whose pet has a malformed $field is null (D-16)', () {
        final pet = petJson()..[field] = value;

        expect(OwnedPet.tryFromJson(ownedPetJson(pet: pet)), isNull);
      });
    }

    test('a bare pet with a malformed name is null (D-15, D-16)', () {
      expect(OwnedPet.tryFromJson(petJson()..['name'] = 7), isNull);
    });
  });

  group('companion state (BE Phase 23)', () {
    OwnedPet entryOf(Map<String, dynamic> json) => OwnedPet.tryFromJson(json)!;

    test('reads name, defeated and the three dates as served '
        '(D-09, D-23, D-24)', () {
      final owned = entryOf(
        ownedPetJson(
          name: 'Fenrir',
          defeated: true,
          lifeAsOf: '2026-11-14T10:00:00.000Z',
          fullLifeAt: '2026-11-14T11:20:00.000Z',
          potionRecoveryUntil: '2026-11-14T10:20:00.000Z',
        ),
      );

      expect(owned.name, 'Fenrir');
      expect(owned.isDefeated, isTrue);
      expect(owned.lifeAsOf, DateTime.utc(2026, 11, 14, 10));
      expect(owned.fullLifeAt, DateTime.utc(2026, 11, 14, 11, 20));
      expect(owned.potionRecoveryUntil, DateTime.utc(2026, 11, 14, 10, 20));
    });

    test('a blank name reads null and the species stays the wording '
        '(D-20)', () {
      expect(entryOf(ownedPetJson(name: '   ')).name, isNull);
      expect(entryOf(ownedPetJson(name: ' Fenrir ')).name, 'Fenrir');
    });

    test('absent or malformed new fields keep the entry (D-24)', () {
      final bare = entryOf(ownedPetJson());

      expect(bare.name, isNull);
      expect(bare.isDefeated, isFalse);
      expect(bare.lifeAsOf, isNull);
      expect(bare.fullLifeAt, isNull);
      expect(bare.potionRecoveryUntil, isNull);
      expect(entryOf(ownedPetJson(defeated: 'yes')).isDefeated, isFalse);
      expect(entryOf(ownedPetJson(lifeAsOf: 'nope')).lifeAsOf, isNull);
      expect(entryOf(ownedPetJson(fullLifeAt: 5)).fullLifeAt, isNull);
      expect(
        entryOf(ownedPetJson(potionRecoveryUntil: true)).potionRecoveryUntil,
        isNull,
      );
      expect(entryOf(ownedPetJson(name: 7)).name, isNull);
    });

    test('dates are read in UTC (D-24)', () {
      final lifeAsOf = entryOf(
        ownedPetJson(lifeAsOf: '2026-11-14T12:00:00.000+02:00'),
      ).lifeAsOf!;

      expect(lifeAsOf.isUtc, isTrue);
      expect(lifeAsOf.hour, 10);
    });

    test('toJson round trip keeps the new fields (D-23)', () {
      final owned = entryOf(
        ownedPetJson(
          name: 'Fenrir',
          defeated: true,
          lifeAsOf: '2026-11-14T10:00:00.000Z',
          fullLifeAt: '2026-11-14T11:20:00.000Z',
          potionRecoveryUntil: '2026-11-14T10:20:00.000Z',
        ),
      );

      expect(OwnedPet.tryFromJson(owned.toJson()), owned);
      expect(owned.toJson()['name'], 'Fenrir');
      expect(owned.toJson()['defeated'], isTrue);
    });

    test('props tell two entries apart by each new field (D-09)', () {
      final base = entryOf(ownedPetJson());
      final variants = <Map<String, dynamic>>[
        ownedPetJson(name: 'Fenrir'),
        ownedPetJson(defeated: true),
        ownedPetJson(lifeAsOf: '2026-11-14T10:00:00.000Z'),
        ownedPetJson(fullLifeAt: '2026-11-14T11:20:00.000Z'),
        ownedPetJson(potionRecoveryUntil: '2026-11-14T10:20:00.000Z'),
      ];

      for (final variant in variants) {
        expect(entryOf(variant), isNot(base));
      }
    });
  });

  group('companion level (BE Phase 23)', () {
    OwnedPet entryOf(Map<String, dynamic> json) => OwnedPet.tryFromJson(json)!;

    test('reads the companion level and its own max life (D-37, D-38)', () {
      final owned = entryOf(ownedPetJson(level: 3, maxLifePoints: 140));

      expect(owned.level, 3);
      expect(owned.ownMaxLifePoints, 140);
    });

    test('a missing or malformed level or own max keeps the entry and reads '
        'null (D-38)', () {
      final bare = entryOf(ownedPetJson());

      expect(bare.level, isNull);
      expect(bare.ownMaxLifePoints, isNull);
      expect(entryOf(ownedPetJson(level: 0)).level, isNull);
      expect(entryOf(ownedPetJson(level: '3')).level, isNull);
      expect(entryOf(ownedPetJson(maxLifePoints: -1)).ownMaxLifePoints, isNull);
      expect(entryOf(ownedPetJson(maxLifePoints: 0)).ownMaxLifePoints, isNull);
    });

    test('effectiveMaxLifePoints is the own max, else the species max '
        '(D-38)', () {
      final species = petJson(maxLifePoints: 100);

      expect(
        entryOf(
          ownedPetJson(pet: species, maxLifePoints: 140),
        ).effectiveMaxLifePoints,
        140,
      );
      expect(entryOf(ownedPetJson(pet: species)).effectiveMaxLifePoints, 100);
      expect(entryOf(ownedPetJson()).effectiveMaxLifePoints, isNull);
    });

    test('toJson round trip keeps level and the own max (D-37)', () {
      final owned = entryOf(ownedPetJson(level: 3, maxLifePoints: 140));

      expect(OwnedPet.tryFromJson(owned.toJson()), owned);
      expect(owned.toJson()['level'], 3);
      expect(owned.toJson()['maxLifePoints'], 140);
    });

    test('props tell two entries apart by level and own max (D-37, D-38)', () {
      final base = entryOf(ownedPetJson());

      expect(entryOf(ownedPetJson(level: 2)), isNot(base));
      expect(entryOf(ownedPetJson(maxLifePoints: 140)), isNot(base));
    });
  });

  test('a bare catalogue pet map is dropped (D-03, D-15)', () {
    expect(OwnedPet.tryFromJson(petJson()), isNull);
  });
}
