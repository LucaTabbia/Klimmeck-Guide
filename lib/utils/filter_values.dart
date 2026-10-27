import 'package:klimmeck_guide/models/asset_quantity.dart';
import 'package:klimmeck_guide/models/enums/effect_type.dart';
import 'package:klimmeck_guide/models/enums/equip_type.dart';

/// Valori di [all] presenti in [found], nell'ordine dell'enum; i null cadono
/// (chi ha tipo null resta solo sotto «Tutti», D-23).
List<T> presentFilterValues<T extends Enum>(List<T> all, Iterable<T?> found) {
  final present = found.whereType<T>().toSet();
  return all.where(present.contains).toList();
}

/// La selezione sopravvive solo se il suo tipo è ancora nella lista;
/// altrimenti torna «Tutti» (null, D-23).
T? retainedFilterSelection<T>(T? selected, List<T> present) =>
    present.contains(selected) ? selected : null;

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
