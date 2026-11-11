import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/asset_quantity.dart';

import '../helpers/fixtures/shop_fixtures.dart';

Map<String, dynamic> _withItemField(
  Map<String, dynamic> entry,
  String field,
  Object? value,
) => {
  ...entry,
  'item': {...entry['item'] as Map<String, dynamic>, field: value},
};

void main() {
  group('AssetQuantity.tryFromJson', () {
    test('parses a loot entry and an equipment entry (D-16)', () {
      final loot = AssetQuantity.tryFromJson(lootAssetJson(quantity: 3));
      final equipment = AssetQuantity.tryFromJson(equipmentAssetJson());

      expect(loot?.item?.isLoot, isTrue);
      expect(loot?.quantity, 3);
      expect(equipment?.item?.isEquipment, isTrue);
      expect(equipment?.item?.id, 'e-sword');
    });

    test('an entry whose item has an unknown effect is null (D-16)', () {
      expect(
        AssetQuantity.tryFromJson(
          _withItemField(lootAssetJson(), 'effect', 'teleport'),
        ),
        isNull,
      );
    });

    test('an entry whose item has an unknown rarity is null (D-16)', () {
      expect(
        AssetQuantity.tryFromJson(
          _withItemField(lootAssetJson(), 'rarity', 'mythic'),
        ),
        isNull,
      );
    });

    test('an entry whose item has an unknown equip type is null (D-16)', () {
      expect(
        AssetQuantity.tryFromJson(
          _withItemField(equipmentAssetJson(), 'equipType', 'cape'),
        ),
        isNull,
      );
    });

    test('an entry that is not a map is null (D-16)', () {
      expect(AssetQuantity.tryFromJson('x'), isNull);
      expect(AssetQuantity.tryFromJson(null), isNull);
      expect(AssetQuantity.tryFromJson(const [1]), isNull);
    });

    test('an entry without an item is kept (D-16)', () {
      final entry = AssetQuantity.tryFromJson(const <String, dynamic>{
        'quantity': 2,
      });

      expect(entry, isNotNull);
      expect(entry?.item, isNull);
      expect(entry?.quantity, 2);
    });
  });
}
