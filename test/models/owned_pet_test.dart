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

  test('a bare catalogue pet map is dropped (D-03, D-15)', () {
    expect(OwnedPet.tryFromJson(petJson()), isNull);
  });
}
