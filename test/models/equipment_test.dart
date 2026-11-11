import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/enums/equip_type.dart';
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
}
