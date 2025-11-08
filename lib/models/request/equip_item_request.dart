import '../enums/slot_type.dart';

class EquipItemRequest {
  EquipItemRequest({
    required this.id,
    required this.itemId,
    required this.slotType,
  });

  String id;
  String? itemId;
  SlotType slotType;

  Map<String, dynamic> toJson() => {
    "id": id,
    "itemId": itemId,
    "slotType": slotType.name,
  };
}
