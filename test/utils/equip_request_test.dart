import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/enums/slot_type.dart';
import 'package:klimmeck_guide/models/equipment.dart';
import 'package:klimmeck_guide/models/equipment_item.dart';
import 'package:klimmeck_guide/utils/equip_request.dart';
import 'package:klimmeck_guide/utils/equipment_copies.dart';

final _shield = EquipmentItem.fromJson(const {
  'id': 'e-shield',
  'name': 'Scudo anti-fulmine',
  'equipType': 'shield',
});

Equipment _wearing(Map<String, EquipmentItem> slots) => Equipment.fromJson({
  for (final MapEntry(:key, :value) in slots.entries) key: value.toJson(),
});

void main() {
  const characterId = 'c-1';

  test('a spare copy goes into the selected slot and takes its mark', () {
    final tap = copyTapFor(
      characterId: characterId,
      copy: EquipmentCopy(item: _shield, index: 1),
      selectedSlot: SlotType.rightHand,
      worn: _wearing({}),
    );

    expect(tap?.request?.toJson(), {
      'id': characterId,
      'itemId': 'e-shield',
      'slotType': 'rightHand',
    });
    expect(
      tap?.applyTo(const CopyMarks()),
      const CopyMarks().marking(SlotType.rightHand, 1),
    );
  });

  test('a worn copy comes off its slot and drops its mark', () {
    final tap = copyTapFor(
      characterId: characterId,
      copy: EquipmentCopy(item: _shield, index: 0, wornIn: SlotType.leftHand),
      selectedSlot: null,
      worn: _wearing({'leftHand': _shield}),
    );

    expect(tap?.request?.toJson()['itemId'], isNull);
    expect(tap?.request?.slotType, SlotType.leftHand);
    expect(
      tap?.applyTo(const CopyMarks().marking(SlotType.leftHand, 0)),
      const CopyMarks(),
    );
  });

  test('a spare copy of the piece already in the slot only moves the mark', () {
    final tap = copyTapFor(
      characterId: characterId,
      copy: EquipmentCopy(item: _shield, index: 0),
      selectedSlot: SlotType.rightHand,
      worn: _wearing({'rightHand': _shield}),
    );

    expect(tap?.request, isNull);
    expect(
      tap?.applyTo(const CopyMarks().marking(SlotType.rightHand, 1)),
      const CopyMarks().marking(SlotType.rightHand, 0),
    );
  });

  test('asks nothing for a spare copy with no slot selected', () {
    expect(
      copyTapFor(
        characterId: characterId,
        copy: EquipmentCopy(item: _shield, index: 0),
        selectedSlot: null,
        worn: _wearing({}),
      ),
      isNull,
    );
  });
}
