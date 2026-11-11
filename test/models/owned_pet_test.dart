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

  group('window (BE before Phase 19)', () {
    test(
      'a bare catalogue pet is read as an entry with xp 0 and life 0 (D-15)',
      () {
        final owned = OwnedPet.tryFromJson(petJson());

        expect(owned?.pet.id, 'pet-travel-horse');
        expect(owned?.xp, 0);
        expect(owned?.currentLifePoints, 0);
      },
    );
  });
}
