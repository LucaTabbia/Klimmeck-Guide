import 'coins.dart';
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
  final Coins? buyPrice;
  final Coins? sellPrice;
  final int? power;
  final String id;
  final String? name;

  factory LootItem.fromJson(Map<String, dynamic> json) => LootItem(
    id: json["id"],
    name: json["name"],
    sellPrice: json['sellPrice'] != null ? Coins.fromJson(json['sellPrice']) : null,
    buyPrice: json['buyPrice'] != null ? Coins.fromJson(json['buyPrice']) : null,
    power: json["power"] != null ? (json["power"] as num).toInt() : null,
    effect: json['effect'] != null ? EffectType.values.byName(json['effect']) : null,
    rarity: json['rarity'] != null ? RarityType.values.byName(json['rarity']) : null,
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "buyPrice": buyPrice?.toJson(),
    "sellPrice": sellPrice?.toJson(),
    "power": power,
    "effect": effect?.name,
    "rarity": rarity?.name,
  };
}
