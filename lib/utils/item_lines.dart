import 'package:klimmeck_guide/models/loot_item.dart';

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
