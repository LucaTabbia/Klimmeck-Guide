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

  final EffectType? effect;
  final RarityType? rarity;
  final int? buyPrice;
  final int? sellPrice;
  final int? power;
  final String id;
  final String? name;

  factory LootItem.fromJson(Map<String, dynamic> json) => LootItem(
    id: json["id"],
    name: json["name"],
    buyPrice: json["buyPrice"] != null ? (json["buyPrice"] as num).toInt() : null,
    sellPrice: json["sellPrice"] != null ? (json["sellPrice"] as num).toInt() : null,
    power: json["power"] != null ? (json["power"] as num).toInt() : null,
    effect: json['effect'] != null ? EffectType.values.byName(json['effect']) : null,
    rarity: json['rarity'] != null ? RarityType.values.byName(json['rarity']) : null,
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "buyPrice": buyPrice,
    "sellPrice": sellPrice,
    "power": power,
    "effect": effect?.name,
    "rarity": rarity?.name,
  };
}
