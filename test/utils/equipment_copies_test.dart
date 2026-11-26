import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/asset_quantity.dart';
import 'package:klimmeck_guide/models/enums/slot_type.dart';
import 'package:klimmeck_guide/models/equipment.dart';
import 'package:klimmeck_guide/models/equipment_item.dart';
import 'package:klimmeck_guide/utils/equipment_copies.dart';

final _shield = EquipmentItem.fromJson(const {
  'id': 'e-shield',
  'name': 'Scudo anti-fulmine',
  'equipType': 'shield',
});

final _helm = EquipmentItem.fromJson(const {
  'id': 'e-helm',
  'name': 'Elmo di ferro',
  'equipType': 'helm',
});

Equipment _wearing(Map<String, EquipmentItem> slots) => Equipment.fromJson({
  for (final MapEntry(:key, :value) in slots.entries) key: value.toJson(),
});

final _owned = [
  AssetQuantity(item: _shield, quantity: 2),
  AssetQuantity(item: _helm, quantity: 1),
];

List<SlotType?> _wornInOf(List<EquipmentCopy> copies) =>
    copies.map((copy) => copy.wornIn).toList();

void main() {
  group('copiesFittingSlot', () {
    test('lists one card per owned copy in a fixed order', () {
      final copies = copiesFittingSlot(
        owned: _owned,
        worn: _wearing({}),
        slot: SlotType.rightHand,
        marks: const CopyMarks(),
      );

      expect(copies, [
        EquipmentCopy(item: _shield, index: 0),
        EquipmentCopy(item: _shield, index: 1),
      ]);
    });

    test('marks the first copy when nothing chose one', () {
      final copies = copiesFittingSlot(
        owned: _owned,
        worn: _wearing({'rightHand': _shield}),
        slot: SlotType.rightHand,
        marks: const CopyMarks(),
      );

      expect(_wornInOf(copies), [SlotType.rightHand, null]);
    });

    test('keeps the mark on the copy the player put in the slot', () {
      final copies = copiesFittingSlot(
        owned: _owned,
        worn: _wearing({'rightHand': _shield}),
        slot: SlotType.leftHand,
        marks: const CopyMarks().marking(SlotType.rightHand, 1),
      );

      expect(_wornInOf(copies), [null, SlotType.rightHand]);
    });

    test('gives each hand its own copy', () {
      final copies = copiesFittingSlot(
        owned: _owned,
        worn: _wearing({'leftHand': _shield, 'rightHand': _shield}),
        slot: SlotType.leftHand,
        marks: const CopyMarks().marking(SlotType.rightHand, 0),
      );

      expect(_wornInOf(copies), [SlotType.rightHand, SlotType.leftHand]);
    });

    test('ignores a mark the server no longer backs', () {
      final copies = copiesFittingSlot(
        owned: _owned,
        worn: _wearing({}),
        slot: SlotType.rightHand,
        marks: const CopyMarks().marking(SlotType.rightHand, 1),
      );

      expect(_wornInOf(copies), [null, null]);
    });
  });

  test('wornCopies lists one card per worn slot', () {
    final copies = wornCopies(
      owned: _owned,
      worn: _wearing({
        'head': _helm,
        'leftHand': _shield,
        'rightHand': _shield,
      }),
      marks: const CopyMarks().marking(SlotType.leftHand, 1),
    );

    expect(copies, [
      EquipmentCopy(item: _shield, index: 1, wornIn: SlotType.leftHand),
      EquipmentCopy(item: _shield, index: 0, wornIn: SlotType.rightHand),
      EquipmentCopy(item: _helm, index: 0, wornIn: SlotType.head),
    ]);
  });

  group('isBlockedFor', () {
    final inLeft = EquipmentCopy(
      item: _shield,
      index: 0,
      wornIn: SlotType.leftHand,
    );

    test('a copy worn in another slot is blocked', () {
      expect(inLeft.isBlockedFor(SlotType.rightHand), isTrue);
    });

    test('a copy worn in the selected slot is not blocked', () {
      expect(inLeft.isBlockedFor(SlotType.leftHand), isFalse);
    });

    test('nothing is blocked with no slot selected', () {
      expect(inLeft.isBlockedFor(null), isFalse);
    });
  });
}
