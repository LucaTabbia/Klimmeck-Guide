import 'enums/effect_type.dart';
import 'enums/rarity_type.dart';

class LootItem {
  LootItem({
    required this.id,
    required this.name,
    required this.effect,
    required this.rarity,
    required this.buyPrice,
    required this.sellPrice,
    required this.power,
  });

  final EffectType effect;
  final RarityType rarity;
  final int buyPrice;
  final int sellPrice;
  final int power;
  final String id;
  final String name;

  factory LootItem.fromJson(Map<String, dynamic> json) => LootItem(
    id: json["id"],
    name: json["name"],
    buyPrice: json["buyPrice"].toInt(),
    sellPrice: json["sellPrice"].toInt(),
    power: json["power"].toInt(),
    effect: EffectType.values.byName(json['effect']),
    rarity: RarityType.values.byName(json['effect']),
  );

  Map<String, dynamic> toJson() => {"id": id, "name": name};
}
