import 'package:klimmeck_guide/models/enums/slot_type.dart';
import 'package:klimmeck_guide/models/equipment.dart';
import 'package:klimmeck_guide/models/equipment_item.dart';
import 'package:klimmeck_guide/models/request/equip_item_request.dart';

/// Richiesta del tocco su un pezzo nel Diario: lo equipaggia nello slot scelto
/// finché resta una copia libera, altrimenti lo toglie; null se non c'è nulla
/// da chiedere. Le mani le sistema il BE (armi a due mani comprese).
EquipItemRequest? equipRequestFor({
  required String characterId,
  required EquipmentItem item,
  required SlotType? selectedSlot,
  required Equipment worn,
  required int ownedCopies,
}) {
  final wornSlots = worn.slotsWearing(item.id);
  final canWearInSelected =
      selectedSlot != null &&
      !wornSlots.contains(selectedSlot) &&
      wornSlots.length < ownedCopies;
  if (canWearInSelected) {
    return EquipItemRequest(
      id: characterId,
      itemId: item.id,
      slotType: selectedSlot,
    );
  }
  if (wornSlots.isEmpty) return null;
  final slotToEmpty = wornSlots.contains(selectedSlot)
      ? selectedSlot!
      : wornSlots.first;
  return EquipItemRequest(id: characterId, itemId: null, slotType: slotToEmpty);
}
