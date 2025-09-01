import 'package:klimmeck_guide/models/asset_item.dart';

import 'coins.dart';
import 'enums/effect_type.dart';
import 'enums/rarity_type.dart';

class LootItem extends AssetItem {
  LootItem({
    required super.id,
    required super.name,
    required super.rarity,
    required super.buyPrice,
    required super.sellPrice,
    required this.power,
    required this.effect,
  });

  final EffectType? effect;
  final int? power;

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
