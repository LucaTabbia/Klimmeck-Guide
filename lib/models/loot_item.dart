import 'package:equatable/equatable.dart';
import 'package:klimmeck_guide/models/asset_item.dart';

import 'coins.dart';
import 'enums/effect_type.dart';
import 'enums/injury_type.dart';
import 'enums/rarity_type.dart';

class LootItem extends AssetItem with EquatableMixin {
  const LootItem({
    required super.id,
    required super.name,
    required super.description,
    required super.rarity,
    required super.buyPrice,
    required super.sellPrice,
    required this.power,
    required this.effect,
    this.canHeal = const [],
  });

  final EffectType? effect;
  final int? power;

  /// Ferite che un oggetto heal può curare; vuota quando il filo non le serve
  /// (i documenti con i soli simpleFields) o manda qualcosa che non è una lista.
  final List<InjuryType> canHeal;

  factory LootItem.fromJson(Map<String, dynamic> json) => LootItem(
    id: json['id'],
    name: json['name'],
    // il documento `quests` seleziona gli item con i soli simpleFields
    description: json['description'] ?? '',
    sellPrice: json['sellPrice'] != null
        ? Coins.fromJson(json['sellPrice'])
        : null,
    buyPrice: json['buyPrice'] != null
        ? Coins.fromJson(json['buyPrice'])
        : null,
    power: json['power'] != null ? (json['power'] as num).toInt() : null,
    effect: json['effect'] != null
        ? EffectType.values.byName(json['effect'])
        : null,
    rarity: json['rarity'] != null
        ? RarityType.values.byName(json['rarity'])
        : null,
    canHeal: injuryTypesFrom(json['canHeal']),
  );

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'buyPrice': buyPrice?.toJson(),
    'sellPrice': sellPrice?.toJson(),
    'power': power,
    'effect': effect?.name,
    'rarity': rarity?.name,
    'canHeal': canHeal.map((type) => type.name).toList(),
  };

  LootItem copyWith({
    String? id,
    String? name,
    String? description,
    RarityType? rarity,
    Coins? buyPrice,
    Coins? sellPrice,
    int? power,
    EffectType? effect,
    List<InjuryType>? canHeal,
  }) {
    return LootItem(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      rarity: rarity ?? this.rarity,
      buyPrice: buyPrice ?? this.buyPrice,
      sellPrice: sellPrice ?? this.sellPrice,
      power: power ?? this.power,
      effect: effect ?? this.effect,
      canHeal: canHeal ?? this.canHeal,
    );
  }

  @override
  List<Object?> get props => [...super.props, power, effect, canHeal];
}
