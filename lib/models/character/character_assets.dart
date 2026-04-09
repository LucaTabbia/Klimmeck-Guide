import 'package:equatable/equatable.dart';
import 'package:klimmeck_guide/models/active_spell.dart';
import 'package:klimmeck_guide/models/asset_quantity.dart';
import 'package:klimmeck_guide/models/equipment.dart';
import 'package:klimmeck_guide/models/pet.dart';

class CharacterAssets extends Equatable {
  const CharacterAssets({
    required this.ownedItems,
    required this.wearedEquipment,
    required this.ownedEquipments,
    required this.activeSpells,
    required this.pet,
  });

  final List<AssetQuantity>? ownedEquipments;
  final List<AssetQuantity>? ownedItems;
  final Equipment? wearedEquipment;
  final List<ActiveSpell>? activeSpells;
  final Pet? pet;

  factory CharacterAssets.fromJson(Map<String, dynamic> json) =>
      CharacterAssets(
        ownedEquipments: json['ownedEquipments'] != null
            ? List<AssetQuantity>.from(
                json['ownedEquipments'].map((x) => AssetQuantity.fromJson(x)),
              )
            : [],
        ownedItems: json['ownedItems'] != null
            ? List<AssetQuantity>.from(
                json['ownedItems'].map((x) => AssetQuantity.fromJson(x)),
              )
            : [],
        activeSpells: json['activeSpells'] != null
            ? List<ActiveSpell>.from(
                json['activeSpells'].map((x) => ActiveSpell.fromJson(x)),
              )
            : [],
        wearedEquipment: json['wearedEquipment'] != null
            ? Equipment.fromJson(json['wearedEquipment'])
            : null,
        pet: json['pet'] != null ? Pet.fromJson(json['pet']) : null,
      );

  Map<String, dynamic> toJson() => {
    "ownedEquipments": ownedEquipments?.map((e) => e.toJson()).toList(),
    "ownedItems": ownedItems?.map((e) => e.toJson()).toList(),
    "activeSpells": activeSpells?.map((e) => e.toJson()).toList(),
    "wearedEquipment": wearedEquipment?.toJson(),
    "pet": pet?.id,
  };

  @override
  List<Object?> get props => [
    ownedItems,
    ownedEquipments,
    wearedEquipment,
    activeSpells,
    pet,
  ];
}
