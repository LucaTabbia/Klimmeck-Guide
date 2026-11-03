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
