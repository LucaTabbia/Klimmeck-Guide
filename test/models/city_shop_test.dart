import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/city_shop.dart';
import 'package:klimmeck_guide/models/pet.dart';

import '../helpers/fixtures/shop_fixtures.dart';

void main() {
  group('CityShop', () {
    test('parses the city id, equipment, loot and pets of the pool (D-01)', () {
      final shop = CityShop.fromJson(
        cityShopJson(pets: [petJson(), catPetJson()]),
      );

      expect(shop.cityId, 'city-talmvere');
      expect(shop.equipment.single.item?.id, 'e-sword');
      expect(shop.equipment.single.item?.isEquipment, isTrue);
      expect(shop.loot.single.item?.id, 'l-potion');
      expect(shop.loot.single.item?.isLoot, isTrue);
      expect(shop.pets.map((p) => p.id), ['pet-travel-horse', 'pet-cat']);
    });

    test('defaults absent lists to empty pools', () {
      final shop = CityShop.fromJson({
        'city': {'id': 'c'},
      });

      expect(shop.equipment, isEmpty);
      expect(shop.loot, isEmpty);
      expect(shop.pets, isEmpty);
    });

    test('throws FormatException when the city id is missing', () {
      expect(
        () => CityShop.fromJson({'equipment': [], 'loot': [], 'pets': []}),
        throwsFormatException,
      );
      expect(
        () => CityShop.fromJson({'city': <String, dynamic>{}}),
        throwsFormatException,
      );
    });

    test('exposes unmodifiable lists', () {
      final shop = CityShop.fromJson(cityShopJson());

      expect(() => shop.equipment.clear(), throwsUnsupportedError);
      expect(() => shop.loot.clear(), throwsUnsupportedError);
      expect(
        () => shop.pets.add(Pet.fromJson(catPetJson())),
        throwsUnsupportedError,
      );
    });
  });

  group('entry boundaries (Phase 19)', () {
    test('drops a pool loot entry with an unknown effect (D-16)', () {
      final broken = lootAssetJson(id: 'l-broken');
      (broken['item'] as Map<String, dynamic>)['effect'] = 'teleport';

      final shop = CityShop.fromJson(
        cityShopJson(loot: [broken, lootAssetJson()]),
      );

      expect(shop.loot.map((entry) => entry.item?.id), ['l-potion']);
      expect(shop.equipment, hasLength(1));
    });

    test('drops a pool equipment entry with an unknown rarity (D-16)', () {
      final shop = CityShop.fromJson(
        cityShopJson(
          equipment: [
            equipmentAssetJson(),
            equipmentAssetJson(id: 'e-broken', rarity: 'mythic'),
          ],
        ),
      );

      expect(shop.equipment.map((entry) => entry.item?.id), ['e-sword']);
    });

    test('drops a pool pet that is not a map or has no id (D-16)', () {
      final shop = CityShop.fromJson({
        ...cityShopJson(),
        'pets': [
          petJson(),
          'x',
          {'name': 'senza id'},
        ],
      });

      expect(shop.pets.map((pet) => pet.id), ['pet-travel-horse']);
    });

    test('a pool without a city id still throws (D-16)', () {
      expect(
        () => CityShop.fromJson({
          'equipment': [equipmentAssetJson()],
          'loot': [lootAssetJson()],
          'pets': [petJson()],
        }),
        throwsFormatException,
      );
    });
  });
}
