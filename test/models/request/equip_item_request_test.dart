import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/enums/slot_type.dart';
import 'package:klimmeck_guide/models/request/equip_item_request.dart';

void main() {
  test('sends the feet slot name on the wire (D-04, D-19)', () {
    final request = EquipItemRequest(
      id: 'c',
      itemId: 'boots',
      slotType: SlotType.values.byName('feet'),
    );

    expect(request.toJson(), {
      'id': 'c',
      'itemId': 'boots',
      'slotType': 'feet',
    });
  });

  test('sends a null item to unequip (D-04)', () {
    final request = EquipItemRequest(
      id: 'c',
      itemId: null,
      slotType: SlotType.head,
    );

    expect(request.toJson(), {'id': 'c', 'itemId': null, 'slotType': 'head'});
  });
}
