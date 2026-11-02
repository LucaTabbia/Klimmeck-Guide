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
}
