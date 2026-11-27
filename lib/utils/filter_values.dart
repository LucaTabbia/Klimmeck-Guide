import 'package:klimmeck_guide/models/asset_quantity.dart';
import 'package:klimmeck_guide/models/enums/effect_type.dart';
import 'package:klimmeck_guide/models/enums/equip_type.dart';

/// Valori di [all] presenti in [found], nell'ordine dell'enum; i null cadono
/// (chi ha tipo null compare solo senza filtri, D-23).
List<T> presentFilterValues<T extends Enum>(List<T> all, Iterable<T?> found) {
  final present = found.whereType<T>().toSet();
  return all.where(present.contains).toList();
}

/// Della selezione restano solo i tipi ancora presenti nella lista; una
/// selezione vuota mostra tutto (D-23).
Set<T> retainedFilterSelections<T>(Set<T> selected, List<T> present) =>
    selected.intersection(present.toSet());

/// Una selezione vuota fa passare ogni riga, anche quelle senza tipo; una
/// piena solo i suoi tipi.
bool matchesFilterSelection<T>(Set<T> selected, T? value) =>
    selected.isEmpty || selected.contains(value);

/// Il tocco su un chip lo aggiunge alla selezione o lo toglie.
Set<T> toggledFilterSelection<T>(Set<T> selected, T value) =>
    selected.contains(value)
    ? (Set.of(selected)..remove(value))
    : {...selected, value};

List<EquipType> presentEquipTypes(Iterable<AssetQuantity> assets) =>
    presentFilterValues(
      EquipType.values,
      assets.map((asset) => asset.item?.asEquipment?.equipType),
    );

List<EffectType> presentEffectTypes(Iterable<AssetQuantity> assets) =>
    presentFilterValues(
      EffectType.values,
      assets.map((asset) => asset.item?.asLoot?.effect),
    );
