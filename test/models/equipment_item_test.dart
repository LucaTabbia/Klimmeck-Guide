import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/enums/accessory_use_type.dart';
import 'package:klimmeck_guide/models/enums/equip_sub_type.dart';
import 'package:klimmeck_guide/models/equipment_item.dart';

EquipmentItem _piece(String equipType, {List<String>? uses, String? subType}) =>
    EquipmentItem.fromJson({
      'id': 'eq-$equipType',
      'name': 'Pezzo',
      'equipType': equipType,
      'rarity': 'rare',
      'damages': {'base': [], 'energy': []},
      if (uses != null) 'accessoryUseTypes': uses,
      if (subType != null) 'equipSubType': subType,
    });

void main() {
  group('equipSubType', () {
    test('parses the family of a weapon', () {
      expect(
        _piece('weapon', subType: 'greatsword').equipSubType,
        EquipSubType.greatsword,
      );
    });

    test('a piece without the field or with an unknown family has none', () {
      expect(_piece('helm').equipSubType, isNull);
      expect(_piece('weapon', subType: 'whip').equipSubType, isNull);
    });

    test('round-trips and takes part in equality', () {
      final bow = _piece('weapon', subType: 'bow');

      expect(EquipmentItem.fromJson(bow.toJson()), bow);
      expect(_piece('weapon', subType: 'spear'), isNot(bow));
    });
  });

  test('parses accessoryUseTypes of a ring (D-12)', () {
    expect(_piece('ring', uses: ['attack', 'defense']).accessoryUseTypes, [
      AccessoryUseType.attack,
      AccessoryUseType.defense,
    ]);
  });

  test('drops unknown use names instead of throwing (D-12)', () {
    expect(_piece('ring', uses: ['attack', 'stealth']).accessoryUseTypes, [
      AccessoryUseType.attack,
    ]);
  });

  test('a piece without the field has null use types (D-12)', () {
    expect(_piece('helm').accessoryUseTypes, isNull);
  });

  test('round-trips accessoryUseTypes and lists them in props (D-12)', () {
    final ring = _piece('ring', uses: ['attack', 'defense']);

    expect(EquipmentItem.fromJson(ring.toJson()), ring);
    expect(_piece('ring', uses: ['attack']), isNot(ring));
    expect(
      () => ring.accessoryUseTypes!.add(AccessoryUseType.attack),
      throwsUnsupportedError,
    );
  });
}
