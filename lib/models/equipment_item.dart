import 'package:klimmeck_guide/models/asset_item.dart';
import 'package:klimmeck_guide/models/spell.dart';

import 'coins.dart';
import 'damages.dart';
import 'enums/equip_type.dart';
import 'enums/rarity_type.dart';

class EquipmentItem extends AssetItem {
  EquipmentItem({
    required super.id,
    required super.name,
    required super.rarity,
    required super.sellPrice,
    required super.buyPrice,
    required this.equipType,
    required this.addedSpell,
    required this.damages,
  });

  final EquipType? equipType;
  final Spell? addedSpell;
  final Damages? damages;

  factory EquipmentItem.fromJson(Map<String, dynamic> json) => EquipmentItem(
    id: json['id'],
    name: json['name'],
    equipType: json['equipType'] != null ? EquipType.values.byName(json['equipType']) : null,
    addedSpell: json['addedSpell'] != null ? Spell.fromJson(json['addedSpell']) : null,
    sellPrice: json['sellPrice'] != null ? Coins.fromJson(json['sellPrice']) : null,
    buyPrice: json['buyPrice'] != null ? Coins.fromJson(json['buyPrice']) : null,
    rarity: json['rarity'] != null ? RarityType.values.byName(json['rarity']) : null,
    damages: json["damages"] != null ? Damages.fromJson(json["damages"]) : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'equipType': equipType?.name,
    'addedSpell': addedSpell?.toJson(),
    'sellPrice': sellPrice?.toJson(),
    'buyPrice': buyPrice?.toJson(),
    'rarity': rarity?.name,
    'damages': damages?.toJson(),
  };
}
