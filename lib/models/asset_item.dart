import 'package:equatable/equatable.dart';
import 'package:klimmeck_guide/models/enums/rarity_type.dart';

import 'coins.dart';
import 'equipment_item.dart';
import 'loot_item.dart';

abstract class AssetItem extends Equatable {
  const AssetItem({
    required this.id,
    required this.description,
    required this.name,
    required this.sellPrice,
    required this.buyPrice,
    required this.rarity,
  });

  final String id;
  final String description;
  final String? name;
  final Coins? sellPrice;
  final Coins? buyPrice;
  final RarityType? rarity;

  factory AssetItem.fromJson(Map<String, dynamic> json) {
    if (json['equipType'] != null) {
      return EquipmentItem.fromJson(json);
    } else {
      return LootItem.fromJson(json);
    }
  }

  Map<String, dynamic> toJson();

  @override
  List<Object?> get props => [
    id,
    description,
    name,
    sellPrice,
    buyPrice,
    rarity,
  ];
}
