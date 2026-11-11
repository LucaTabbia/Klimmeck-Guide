import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/character/character_assets.dart';

import '../../helpers/fixtures/shop_fixtures.dart';

void main() {
  group('CharacterAssets', () {
    test('parses ownedPets beside the equipped pet (D-10)', () {
      final assets = CharacterAssets.fromJson({
        'pet': petJson(),
        'ownedPets': [petJson(), catPetJson()],
      });

      expect(assets.pet?.id, 'pet-travel-horse');
      expect(assets.ownedPets.map((p) => p.id), [
        'pet-travel-horse',
        'pet-cat',
      ]);
    });

    test('defaults ownedPets to an empty list when absent (D-11)', () {
      expect(CharacterAssets.fromJson({}).ownedPets, isEmpty);
    });

    test('lists ownedPets in props so a sale re-renders (D-08)', () {
      expect(
        CharacterAssets.fromJson({
          'ownedPets': [petJson(), catPetJson()],
        }),
        isNot(
          CharacterAssets.fromJson({
            'ownedPets': [petJson()],
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

    test('owned lists that are not lists are empty (D-16)', () {
      final assets = CharacterAssets.fromJson({
        'ownedItems': 'x',
        'ownedEquipments': 3,
      });

      expect(assets.ownedItems, isEmpty);
      expect(assets.ownedEquipments, isEmpty);
    });
  });
}
