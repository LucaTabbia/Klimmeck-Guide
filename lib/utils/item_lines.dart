import 'package:klimmeck_guide/models/enums/accessory_use_type.dart';
import 'package:klimmeck_guide/models/enums/effect_type.dart';
import 'package:klimmeck_guide/models/enums/equip_type.dart';
import 'package:klimmeck_guide/models/enums/injury_type.dart';
import 'package:klimmeck_guide/models/equipment_item.dart';
import 'package:klimmeck_guide/models/loot_item.dart';
import 'package:klimmeck_guide/models/loot_recovery.dart';
import 'package:klimmeck_guide/models/pet.dart';
import 'package:klimmeck_guide/models/quest/quest_cure.dart';
import 'package:klimmeck_guide/utils/game_duration_format.dart';

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
      if (item.canHeal.contains(type)) type.label.toLowerCase(),
  ];
  if (labels.isEmpty) return null;
  return 'Cura: ${labels.join(', ')}';
}

/// Riga della cura sul foglio di una quest (D-03): solo le ferite del
/// personaggio che la quest guarisce, nell'ordine del personaggio, in
/// minuscolo; nessuna riga se nessuna corrisponde. È un filtro di
/// visualizzazione: la cura la applica il backend.
String? curableInjuriesLine(
  QuestCure? cure,
  List<InjuryType>? characterInjuries,
) {
  if (cure == null || characterInjuries == null) return null;
  final labels = <String>{
    for (final injury in characterInjuries)
      if (cure.canHeal.contains(injury)) injury.label.toLowerCase(),
  };
  if (labels.isEmpty) return null;
  return 'Cura le tue ferite: ${labels.join(', ')}';
}

/// Riga della vita (D-04): la quota diventa una percentuale, nient'altro;
/// quota piena «al massimo», quota zero nessuna riga.
String? lifeShareLine(QuestCure? cure) {
  if (cure == null) return null;
  final share = cure.lifePointsShare;
  if (share <= 0) return null;
  if (share >= 1) return 'Vita: al massimo';
  final percent = (share * 100).round();
  final article = _elidesArticle(percent) ? "l'" : 'il ';
  return 'Vita: almeno $article$percent%';
}

/// «l'1%», «l'8%», «l'11%», «l'80%»…«l'89%»: i numeri che in italiano
/// iniziano per vocale (D-21).
bool _elidesArticle(int percent) =>
    percent == 1 ||
    percent == 8 ||
    percent == 11 ||
    (percent >= 80 && percent <= 89);

/// Riga «Guarite: …» del foglio esiti e della pozione bevuta (D-06): etichette
/// in minuscolo nell'ordine ricevuto; nessuna riga senza ferite guarite.
String? healedLine(List<InjuryType> injuries) {
  if (injuries.isEmpty) return null;
  final labels = injuries.map((injury) => injury.label.toLowerCase());
  return 'Guarite: ${labels.join(', ')}';
}

/// Riga «Ricarica: …» di una pozione (D-13): il tempo servito dal backend,
/// reso leggibile dall'unico formato di durata del gioco (D-17). I turni non
/// si mostrano.
String? recoveryLine(LootRecovery? recovery) {
  if (recovery == null) return null;
  return 'Ricarica: ${formatGameDuration(recovery.duration)}';
}

/// Conto alla rovescia delle pergamene spente (D-12): il tempo che manca alla
/// fine della ricarica, calcolato da chi chiama sull'ora del server.
String potionReadyInLine(Duration remaining) =>
    'pronta fra ${formatGameDuration(remaining)}';
