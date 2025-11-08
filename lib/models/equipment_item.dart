import 'package:equatable/equatable.dart';
import 'package:klimmeck_guide/models/asset_item.dart';
import 'package:klimmeck_guide/models/spell.dart';

import 'coins.dart';
import 'damages.dart';
import 'enums/equip_type.dart';
import 'enums/rarity_type.dart';

class EquipmentItem extends AssetItem with EquatableMixin {
  const EquipmentItem({
    required super.id,
    required super.name,
    required super.description,
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
    description: json['description'],
    equipType: json['equipType'] != null
        ? EquipType.values.byName(json['equipType'])
        : null,
    addedSpell: json['addedSpell'] != null
        ? Spell.fromJson(json['addedSpell'])
        : null,
    sellPrice: json['sellPrice'] != null
        ? Coins.fromJson(json['sellPrice'])
        : null,
    buyPrice: json['buyPrice'] != null
        ? Coins.fromJson(json['buyPrice'])
        : null,
    rarity: json['rarity'] != null
        ? RarityType.values.byName(json['rarity'])
        : null,
    damages: json["damages"] != null ? Damages.fromJson(json["damages"]) : null,
  );

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'equipType': equipType?.name,
    'addedSpell': addedSpell?.toJson(),
    'sellPrice': sellPrice?.toJson(),
    'buyPrice': buyPrice?.toJson(),
    'rarity': rarity?.name,
    'damages': damages?.toJson(),
  };

  EquipmentItem copyWith({
    String? id,
    String? name,
    String? description,
    RarityType? rarity,
    Coins? sellPrice,
    Coins? buyPrice,
    EquipType? equipType,
    Spell? addedSpell,
    Damages? damages,
  }) {
    return EquipmentItem(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      rarity: rarity ?? this.rarity,
      sellPrice: sellPrice ?? this.sellPrice,
      buyPrice: buyPrice ?? this.buyPrice,
      equipType: equipType ?? this.equipType,
      addedSpell: addedSpell ?? this.addedSpell,
      damages: damages ?? this.damages,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    rarity,
    sellPrice,
    buyPrice,
    equipType,
    addedSpell,
    damages,
  ];
}
