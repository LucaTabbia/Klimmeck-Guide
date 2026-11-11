import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/enums/equip_type.dart';
import 'package:klimmeck_guide/models/enums/slot_type.dart';
import 'package:klimmeck_guide/models/equipment.dart';
import 'package:klimmeck_guide/models/equipment_item.dart';

Map<String, dynamic> _itemJson(
  String id, {
  String equipType = 'helm',
  String rarity = 'common',
}) => {
  'id': id,
  'name': id,
  'description': 'Equipaggiamento $id',
  'equipType': equipType,
  'rarity': rarity,
};

/// Nome dello slot degli stivali prima della BE Phase 19.
const _oldBootsSlot =
    'fo'
    'ots';

void main() {
  group('Equipment.fromJson', () {
    test('parses the worn items slot by slot (D-16)', () {
      final equipment = Equipment.fromJson({
        'head': _itemJson('e-helm'),
        'leftHand': _itemJson('e-sword', equipType: 'weapon'),
      });

      expect(equipment.head?.id, 'e-helm');
      expect(equipment.leftHand?.equipType, EquipType.weapon);
      expect(equipment.values.nonNulls, hasLength(2));
    });

    test('a slot whose item has an unknown equip type is empty and the '
        'others survive (D-16)', () {
      final equipment = Equipment.fromJson({
        'head': _itemJson('e-broken', equipType: 'cape'),
        'chest': _itemJson('e-chest', equipType: 'chestPiece'),
      });

      expect(equipment.head, isNull);
      expect(equipment.chest?.id, 'e-chest');
    });

    test('a slot whose item has an unknown rarity is empty (D-16)', () {
      final equipment = Equipment.fromJson({
        'chest': _itemJson(
          'e-chest',
          equipType: 'chestPiece',
          rarity: 'mythic',
        ),
      });

      expect(equipment.chest, isNull);
    });

    test('a slot that is not a map is empty (D-16)', () {
      expect(Equipment.fromJson({'head': 'helmet'}).head, isNull);
    });
  });

  test('EquipmentItem.tryFromJson returns the item for a readable map and '
      'null otherwise (D-16)', () {
    expect(EquipmentItem.tryFromJson(_itemJson('e-helm'))?.id, 'e-helm');
    expect(
      EquipmentItem.tryFromJson(_itemJson('e-broken', equipType: 'cape')),
      isNull,
    );
    expect(EquipmentItem.tryFromJson('helmet'), isNull);
    expect(EquipmentItem.tryFromJson(null), isNull);
  });

  group('feet slot (BE Phase 19)', () {
    test('parses the boots from the feet key (D-04)', () {
      final equipment = Equipment.fromJson({
        'feet': _itemJson('e-boots', equipType: 'boots'),
      });

      expect(equipment.toJson()['feet'], 'e-boots');
    });

    test('every SlotType name is a key of Equipment.toJson (D-04)', () {
      final keys = Equipment.fromJson({}).toJson();

      for (final slot in SlotType.values) {
        expect(keys.containsKey(slot.name), isTrue, reason: slot.name);
      }
    });

    test('SlotType has the feet member and not the old boots name '
        '(D-04, D-19)', () {
      final names = SlotType.values.asNameMap().keys;

      expect(names, contains('feet'));
      expect(names, isNot(contains(_oldBootsSlot)));
    });
  });
}
