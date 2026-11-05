import 'package:equatable/equatable.dart';
import 'package:klimmeck_guide/models/asset_item.dart';
import 'package:klimmeck_guide/models/spell.dart';

import 'coins.dart';
import 'damages.dart';
import 'enums/accessory_use_type.dart';
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
    this.accessoryUseTypes,
  });

  final EquipType? equipType;
  final Spell? addedSpell;
  final Damages? damages;

  /// Solo anelli e collane (BE D-24); null sugli altri pezzi.
  final List<AccessoryUseType>? accessoryUseTypes;

  factory EquipmentItem.fromJson(Map<String, dynamic> json) => EquipmentItem(
    id: json['id'],
    name: json['name'],
    // il documento `quests` seleziona gli item con i soli simpleFields
    description: json['description'] ?? '',
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
    accessoryUseTypes: _accessoryUseTypesFrom(json['accessoryUseTypes']),
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
    'accessoryUseTypes': accessoryUseTypes?.map((type) => type.name).toList(),
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
    List<AccessoryUseType>? accessoryUseTypes,
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
      accessoryUseTypes: accessoryUseTypes ?? this.accessoryUseTypes,
    );
  }

  @override
  List<Object?> get props => [
    ...super.props,
    equipType,
    addedSpell,
    damages,
    accessoryUseTypes,
  ];
}

List<AccessoryUseType>? _accessoryUseTypesFrom(Object? json) {
  if (json is! List) return null;
  final byName = AccessoryUseType.values.asNameMap();
  return List.unmodifiable(
    json.map((name) => byName[name]).whereType<AccessoryUseType>(),
  );
}
