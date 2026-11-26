import 'package:klimmeck_guide/models/enums/slot_type.dart';
import 'package:klimmeck_guide/models/equipment.dart';
import 'package:klimmeck_guide/models/request/equip_item_request.dart';
import 'package:klimmeck_guide/utils/equipment_copies.dart';

/// Esito del tocco su una scheda: la richiesta al BE (se serve) e dove va il
/// segno della copia ([index] null = lo slot si svuota).
class CopyTap {
  const CopyTap({required this.slot, this.index, this.request});

  final SlotType slot;
  final int? index;
  final EquipItemRequest? request;

  CopyMarks applyTo(CopyMarks marks) => switch (index) {
    final index? => marks.marking(slot, index),
    null => marks.clearing(slot),
  };
}

/// La copia indossata esce dal suo slot; quella libera entra nello slot
/// scelto, oppure ne prende solo il segno se lo slot porta già quel pezzo
/// (per il BE non cambia nulla); null se non c'è nulla da fare. Le mani le
/// sistema il BE (armi a due mani comprese).
CopyTap? copyTapFor({
  required String characterId,
  required EquipmentCopy copy,
  required SlotType? selectedSlot,
  required Equipment worn,
}) {
  if (copy.wornIn case final slot?) {
    return CopyTap(
      slot: slot,
      request: EquipItemRequest(id: characterId, itemId: null, slotType: slot),
    );
  }
  if (selectedSlot == null) return null;
  if (worn.inSlot(selectedSlot)?.id == copy.item.id) {
    return CopyTap(slot: selectedSlot, index: copy.index);
  }
  return CopyTap(
    slot: selectedSlot,
    index: copy.index,
    request: EquipItemRequest(
      id: characterId,
      itemId: copy.item.id,
      slotType: selectedSlot,
    ),
  );
}
