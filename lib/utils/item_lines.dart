import 'package:klimmeck_guide/models/enums/accessory_use_type.dart';
import 'package:klimmeck_guide/models/enums/effect_type.dart';
import 'package:klimmeck_guide/models/enums/equip_type.dart';
import 'package:klimmeck_guide/models/enums/injury_type.dart';
import 'package:klimmeck_guide/models/equipment_item.dart';
import 'package:klimmeck_guide/models/loot_item.dart';
import 'package:klimmeck_guide/models/pet.dart';

// Copy provvisoria (D-19): ogni stringa delle righe oggetto vive qui (D-28).

/// Riga compatta di un oggetto, costruita come quella delle magie
/// («Cura: 12»; potenza assente o 0 → «Cura»; senza effetto nessuna riga, D-26).
String? itemEffectLabel(LootItem item) {
  final effect = item.effect;
  if (effect == null) return null;
  final power = item.power;
  if (power == null || power == 0) return effect.label;
  return '${effect.label}: $power';
}

/// Marcatore del compagno equipaggiato nelle liste (D-07, D-10).
const String companionEquippedMark = 'Al tuo fianco';

/// Riga della sezione «Compagno» senza compagni posseduti (D-15, D-17).
const String noOwnedCompanionsLine = 'Non possiedi compagni';

/// Riga della velocità solo per un compagno da sella (D-07): il FE stampa il
/// moltiplicatore servito, non calcola mai la velocità (D-11).
String? companionSpeedLabel(Pet pet) {
  final modifier = pet.speedModifier;
  if (modifier == null) return null;
  final digits = modifier == modifier.truncateToDouble()
      ? modifier.toInt().toString()
      : modifier.toString().replaceAll('.', ',');
  return 'Velocità ×$digits';
}

/// Riga «Uso» dei gioielli (D-12): solo anelli e collane con usi serviti dal
/// BE, in ordine canonico attacco → difesa; nessun filtro, nessun vincolo.
String? accessoryUsageLine(EquipmentItem item) {
  if (item.equipType != EquipType.ring &&
      item.equipType != EquipType.necklace) {
    return null;
  }
  final uses = item.accessoryUseTypes ?? const [];
  final labels = [
    for (final type in AccessoryUseType.values)
      if (uses.contains(type)) type.label.toLowerCase(),
  ];
  if (labels.isEmpty) return null;
  return 'Uso: ${labels.join(' e ')}';
}

/// Riga «Cura: …» di un oggetto heal: le ferite che può curare, etichette in
/// minuscolo nell'ordine dell'enum, unite da virgola; nessuna riga senza
/// ferite o su un effetto diverso.
String? healedInjuriesLine(LootItem item) {
  if (item.effect != EffectType.heal) return null;
  final labels = [
    for (final type in InjuryType.values)
      if (item.effectedInjuries.contains(type)) type.label.toLowerCase(),
  ];
  if (labels.isEmpty) return null;
  return 'Cura: ${labels.join(', ')}';
}
