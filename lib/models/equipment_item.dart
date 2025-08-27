import 'package:klimmeck_guide/models/enums/damage_type.dart';
import 'package:klimmeck_guide/models/spell.dart';

import 'coins.dart';
import 'enums/energy_type.dart';
import 'enums/equip_type.dart';

class EquipmentItem {
  EquipmentItem({
    required this.id,
    required this.name,
    required this.equipType,
    required this.baseTypes,
    required this.energyType,
    required this.addedSpell,
    required this.basePower,
    required this.energyPower,
    required this.sellPrice,
    required this.buyPrice,
  });

  final String id;
  final String? name;
  final EquipType? equipType;
  final Spell? addedSpell;
  final List<DamageType>? baseTypes;
  final EnergyType? energyType;
  final int? basePower;
  final int? energyPower;
  final Coins? sellPrice;
  final Coins? buyPrice;

  factory EquipmentItem.fromJson(Map<String, dynamic> json) => EquipmentItem(
    id: json['id'],
    name: json['name'],
    baseTypes: json['baseTypes'] != null
        ? List<DamageType>.from(json['baseTypes'].map((x) => DamageType.values.byName(x)))
        : [],
    equipType: json['equipType'] != null ? EquipType.values.byName(json['equipType']) : null,
    energyType: json['energyType'] != null ? EnergyType.values.byName(json['energyType']) : null,
    addedSpell: json['addedSpell'] != null ? Spell.fromJson(json['addedSpell']) : null,
    energyPower: json['energyPower'] != null ? (json['energyPower'] as num).toInt() : null,
    basePower: json['basePower'] != null ? (json['basePower'] as num).toInt() : null,
    sellPrice: json['sellPrice'] != null ? Coins.fromJson(json['sellPrice']) : null,
    buyPrice: json['buyPrice'] != null ? Coins.fromJson(json['buyPrice']) : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'baseTypes': baseTypes?.map((s) => s.name).toList(),
    'equipType': equipType?.name,
    'energyType': energyType?.name,
    'addedSpell': addedSpell?.toJson(),
    'energyPower': energyPower,
    'basePower': basePower,
    'sellPrice': sellPrice?.toJson(),
    'buyPrice': buyPrice?.toJson(),
  };
}
