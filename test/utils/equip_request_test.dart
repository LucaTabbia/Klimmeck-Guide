import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/enums/slot_type.dart';
import 'package:klimmeck_guide/models/equipment.dart';
import 'package:klimmeck_guide/models/equipment_item.dart';
import 'package:klimmeck_guide/utils/equip_request.dart';

EquipmentItem _dagger() => EquipmentItem.fromJson({
  'id': 'e-dagger',
  'name': 'Pugnale',
  'equipType': 'weapon',
  'equipSubType': 'dagger',
});

Equipment _wearing(Map<String, EquipmentItem> slots) => Equipment.fromJson({
  for (final MapEntry(:key, :value) in slots.entries) key: value.toJson(),
});

void main() {
  const characterId = 'c-1';

  test('equips a piece not worn in the selected slot', () {
    final request = equipRequestFor(
      characterId: characterId,
      item: _dagger(),
      selectedSlot: SlotType.leftHand,
      worn: _wearing({}),
      ownedCopies: 1,
    );

    expect(request?.toJson(), {
      'id': characterId,
      'itemId': 'e-dagger',
      'slotType': 'leftHand',
    });
  });

  test('equips a second copy in the other hand', () {
    final request = equipRequestFor(
      characterId: characterId,
      item: _dagger(),
      selectedSlot: SlotType.rightHand,
      worn: _wearing({'leftHand': _dagger()}),
      ownedCopies: 2,
    );

    expect(request?.toJson()['itemId'], 'e-dagger');
    expect(request?.slotType, SlotType.rightHand);
  });

  test('takes the only copy off when no spare copy is left', () {
    final request = equipRequestFor(
      characterId: characterId,
      item: _dagger(),
      selectedSlot: SlotType.rightHand,
      worn: _wearing({'leftHand': _dagger()}),
      ownedCopies: 1,
    );

    expect(request?.toJson()['itemId'], isNull);
    expect(request?.slotType, SlotType.leftHand);
  });

  test('takes the piece off the selected slot that wears it', () {
    final request = equipRequestFor(
      characterId: characterId,
      item: _dagger(),
      selectedSlot: SlotType.rightHand,
      worn: _wearing({'leftHand': _dagger(), 'rightHand': _dagger()}),
      ownedCopies: 2,
    );

    expect(request?.toJson()['itemId'], isNull);
    expect(request?.slotType, SlotType.rightHand);
  });

  test('takes a worn piece off when no slot is selected', () {
    final request = equipRequestFor(
      characterId: characterId,
      item: _dagger(),
      selectedSlot: null,
      worn: _wearing({'rightHand': _dagger()}),
      ownedCopies: 1,
    );

    expect(request?.toJson()['itemId'], isNull);
    expect(request?.slotType, SlotType.rightHand);
  });

  test('asks nothing for a piece not worn and no slot selected', () {
    expect(
      equipRequestFor(
        characterId: characterId,
        item: _dagger(),
        selectedSlot: null,
        worn: _wearing({}),
        ownedCopies: 1,
      ),
      isNull,
    );
  });
}
