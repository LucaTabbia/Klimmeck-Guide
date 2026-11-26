import 'package:equatable/equatable.dart';
import 'package:klimmeck_guide/models/asset_quantity.dart';
import 'package:klimmeck_guide/models/enums/slot_type.dart';
import 'package:klimmeck_guide/models/equipment.dart';
import 'package:klimmeck_guide/models/equipment_item.dart';

/// Una scheda del Diario: la copia [index] di un pezzo posseduto e lo slot
/// che la indossa (null se è libera).
class EquipmentCopy extends Equatable {
  const EquipmentCopy({required this.item, required this.index, this.wornIn});

  final EquipmentItem item;
  final int index;
  final SlotType? wornIn;

  bool get isWorn => wornIn != null;

  /// Indossata in un altro slot rispetto a quello scelto: non si tocca.
  bool isBlockedFor(SlotType? selectedSlot) =>
      selectedSlot != null && isWorn && wornIn != selectedSlot;

  @override
  List<Object?> get props => [item, index, wornIn];
}

/// Quale copia siede in ogni slot. Il BE non distingue le copie di un pezzo:
/// la scheda segnata la sceglie il giocatore e resta ferma; dove non ha scelto
/// vale la prima copia libera.
class CopyMarks extends Equatable {
  const CopyMarks([this._indexBySlot = const {}]);

  final Map<SlotType, int> _indexBySlot;

  CopyMarks marking(SlotType slot, int index) =>
      CopyMarks({..._indexBySlot, slot: index});

  CopyMarks clearing(SlotType slot) =>
      CopyMarks({..._indexBySlot}..remove(slot));

  /// L'indice di copia di ogni slot che indossa [item], coerente con il BE.
  Map<SlotType, int> resolve(EquipmentItem item, int quantity, Equipment worn) {
    final slots = worn.slotsWearing(item.id).take(quantity).toList();
    final resolved = <SlotType, int>{};
    for (final slot in slots) {
      final chosen = _indexBySlot[slot];
      if (chosen != null &&
          chosen < quantity &&
          !resolved.containsValue(chosen)) {
        resolved[slot] = chosen;
      }
    }
    for (final slot in slots.where((slot) => !resolved.containsKey(slot))) {
      resolved[slot] = List.generate(
        quantity,
        (index) => index,
      ).firstWhere((index) => !resolved.containsValue(index));
    }
    return resolved;
  }

  @override
  List<Object?> get props => [_indexBySlot];
}

/// Le copie indossate, una per slot, nell'ordine degli slot.
List<EquipmentCopy> wornCopies({
  required List<AssetQuantity> owned,
  required Equipment worn,
  required CopyMarks marks,
}) => [
  for (final slot in SlotType.values)
    if (worn.inSlot(slot) case final item?)
      EquipmentCopy(
        item: item,
        index: marks.resolve(item, _quantityOf(item, owned), worn)[slot] ?? 0,
        wornIn: slot,
      ),
];

/// Tutte le copie possedute che entrano nello slot, in ordine fisso.
List<EquipmentCopy> copiesFittingSlot({
  required List<AssetQuantity> owned,
  required Equipment worn,
  required SlotType slot,
  required CopyMarks marks,
}) => [
  for (final entry in owned)
    if (entry.item case final EquipmentItem item
        when slot.types.contains(item.equipType))
      ..._copiesOf(item, entry.quantity ?? 0, worn, marks),
];

List<EquipmentCopy> _copiesOf(
  EquipmentItem item,
  int quantity,
  Equipment worn,
  CopyMarks marks,
) {
  final slotByIndex = {
    for (final MapEntry(key: slot, value: index)
        in marks.resolve(item, quantity, worn).entries)
      index: slot,
  };
  return [
    for (var index = 0; index < quantity; index++)
      EquipmentCopy(item: item, index: index, wornIn: slotByIndex[index]),
  ];
}

int _quantityOf(EquipmentItem item, List<AssetQuantity> owned) => owned
    .where((entry) => entry.item?.id == item.id)
    .fold(0, (sum, entry) => sum + (entry.quantity ?? 0));
