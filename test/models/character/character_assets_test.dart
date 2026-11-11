import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/character/character_assets.dart';
import 'package:klimmeck_guide/models/pet.dart';

import '../../helpers/fixtures/shop_fixtures.dart';
import '../../helpers/fixtures/spell_fixtures.dart';

/// Chiave della lista che la BE di oggi serve ancora negli assets.
const _equippedListKey =
    'active'
    'Spells';

/// Chiave dell'equipaggiamento indossato prima della BE Phase 19.
const _oldWornKey =
    'weared'
    'Equipment';

Map<String, dynamic> _helmJson() => {
  'id': 'e-helm',
  'name': 'Elmo',
  'description': 'Un elmo',
  'equipType': 'helm',
  'rarity': 'common',
};

void main() {
  group('CharacterAssets', () {
    test('toJson writes no equipped spell list (D-05)', () {
      final keys = CharacterAssets.fromJson({'ownedPets': []}).toJson().keys;

      expect(keys, contains('ownedPets'));
      expect(keys, isNot(contains(_equippedListKey)));
    });

    test('the assets parse without the equipped spell list (D-05)', () {
      final without = CharacterAssets.fromJson({
        'ownedPets': [ownedPetJson()],
      });
      final withIt = CharacterAssets.fromJson({
        'ownedPets': [ownedPetJson()],
        _equippedListKey: [
          {'usages': 3, 'spell': spellJson()},
        ],
      });

      expect(without.ownedPets, hasLength(1));
      expect(withIt, without);
      expect(withIt.toJson(), without.toJson());
    });

    test('parses the owned pets as entries (D-03)', () {
      final assets = CharacterAssets.fromJson({
        'ownedPets': [
          ownedPetJson(pet: petJson(), xp: 40),
          ownedPetJson(pet: catPetJson()),
        ],
      });

      expect(assets.ownedPets.map((entry) => entry.pet.id), [
        'pet-travel-horse',
        'pet-cat',
      ]);
      expect(assets.ownedPets.first.xp, 40);
    });

    test('drops a malformed owned entry and keeps the others (D-03, D-16)', () {
      final assets = CharacterAssets.fromJson({
        'ownedPets': [
          ownedPetJson(),
          'x',
          <String, dynamic>{'pet': null},
        ],
      });

      expect(assets.ownedPets.map((entry) => entry.pet.id), [
        'pet-travel-horse',
      ]);
    });

    test('a bare pet in the owned list is dropped and the entries stay '
        '(D-03, D-15)', () {
      final assets = CharacterAssets.fromJson({
        'ownedPets': [ownedPetJson(), petJson(id: 'pet-bare')],
      });

      expect(assets.ownedPets.map((entry) => entry.pet.id), [
        'pet-travel-horse',
      ]);
    });

    test('an owned list that is not a list is empty (D-03)', () {
      expect(CharacterAssets.fromJson({}).ownedPets, isEmpty);
      expect(CharacterAssets.fromJson({'ownedPets': 3}).ownedPets, isEmpty);
      expect(
        CharacterAssets.fromJson({'ownedPets': ownedPetJson()}).ownedPets,
        isEmpty,
      );
    });

    test('ownedCatalogPets gives the catalogue pets of the entries in order '
        '(D-03)', () {
      final assets = CharacterAssets.fromJson({
        'ownedPets': [
          ownedPetJson(pet: catPetJson(), xp: 3),
          ownedPetJson(pet: petJson()),
        ],
      });

      expect(assets.ownedCatalogPets, [
        Pet.fromJson(catPetJson()),
        Pet.fromJson(petJson()),
      ]);
    });

    test('the equipped pet stays a catalogue pet (D-03)', () {
      final assets = CharacterAssets.fromJson({
        'pet': petJson(),
        'ownedPets': [ownedPetJson(pet: petJson(), xp: 40)],
      });

      expect(assets.pet, Pet.fromJson(petJson()));
    });

    test('the owned entries are part of the props (D-03)', () {
      expect(
        CharacterAssets.fromJson({
          'ownedPets': [ownedPetJson(xp: 40)],
        }),
        isNot(
          CharacterAssets.fromJson({
            'ownedPets': [ownedPetJson(xp: 41)],
          }),
        ),
      );
      expect(
        CharacterAssets.fromJson({
          'ownedPets': [ownedPetJson(), ownedPetJson(pet: catPetJson())],
        }),
        isNot(
          CharacterAssets.fromJson({
            'ownedPets': [ownedPetJson()],
          }),
        ),
      );
    });
  });

  group('entry boundaries (Phase 19)', () {
    test(
      'drops an owned item with an unknown effect and keeps the others (D-16)',
      () {
        final broken = lootAssetJson(id: 'l-broken');
        (broken['item'] as Map<String, dynamic>)['effect'] = 'teleport';

        final assets = CharacterAssets.fromJson({
          'ownedItems': [broken, lootAssetJson()],
        });

        expect(assets.ownedItems?.map((entry) => entry.item?.id), ['l-potion']);
      },
    );

    test('drops an owned equipment with an unknown equip type and keeps '
        'the others (D-16)', () {
      final broken = equipmentAssetJson(id: 'e-broken');
      (broken['item'] as Map<String, dynamic>)['equipType'] = 'cape';

      final assets = CharacterAssets.fromJson({
        'ownedEquipments': [equipmentAssetJson(), broken],
      });

      expect(assets.ownedEquipments?.map((entry) => entry.item?.id), [
        'e-sword',
      ]);
    });

    test('a malformed owned pet is dropped (D-16)', () {
      final assets = CharacterAssets.fromJson({
        'ownedPets': [
          ownedPetJson(pet: petJson()..['name'] = 7),
          ownedPetJson(pet: catPetJson()),
          ownedPetJson(pet: petJson()..['buyPrice'] = 'un oro'),
        ],
      });

      expect(assets.ownedPets.map((entry) => entry.pet.id), ['pet-cat']);
    });

    test('a malformed equipped pet is null (D-16)', () {
      for (final pet in <Object>[
        petJson()..['name'] = 7,
        petJson()..['maxXp'] = 'trecento',
        <String, dynamic>{'name': 'senza id'},
        'pet-travel-horse',
      ]) {
        final assets = CharacterAssets.fromJson({
          'pet': pet,
          'ownedPets': [ownedPetJson()],
        });

        expect(assets.pet, isNull, reason: '$pet');
        expect(assets.ownedPets, hasLength(1));
      }
    });

    test('owned lists that are not lists are empty (D-16)', () {
      final assets = CharacterAssets.fromJson({
        'ownedItems': 'x',
        'ownedEquipments': 3,
      });

      expect(assets.ownedItems, isEmpty);
      expect(assets.ownedEquipments, isEmpty);
    });
  });

  group('worn equipment (BE Phase 19)', () {
    test('parses the worn equipment from the wornEquipment key (D-04)', () {
      final assets = CharacterAssets.fromJson({
        'wornEquipment': {'head': _helmJson()},
      });

      expect(assets.toJson()['wornEquipment'], isNotNull);
    });

    test('the old assets key is no longer read (D-04)', () {
      final assets = CharacterAssets.fromJson({
        _oldWornKey: {'head': _helmJson()},
      });

      expect(assets.toJson()['wornEquipment'], isNull);
    });
  });
}
