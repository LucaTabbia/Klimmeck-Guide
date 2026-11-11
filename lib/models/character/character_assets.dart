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
    this.ownedPets = const [],
  });

  final List<AssetQuantity>? ownedEquipments;
  final List<AssetQuantity>? ownedItems;
  final Equipment? wearedEquipment;
  final List<ActiveSpell>? activeSpells;

  /// Compagno equipaggiato (quello del viaggio); i posseduti sono [ownedPets] (D-10).
  final Pet? pet;
  final List<Pet> ownedPets;

  factory CharacterAssets.fromJson(Map<String, dynamic> json) =>
      CharacterAssets(
        ownedEquipments: _entriesFrom(json['ownedEquipments']),
        ownedItems: _entriesFrom(json['ownedItems']),
        activeSpells: json['activeSpells'] != null
            ? List<ActiveSpell>.from(
                json['activeSpells'].map((x) => ActiveSpell.fromJson(x)),
              )
            : [],
        wearedEquipment: json['wearedEquipment'] != null
            ? Equipment.fromJson(json['wearedEquipment'])
            : null,
        pet: json['pet'] != null ? Pet.fromJson(json['pet']) : null,
        ownedPets: json['ownedPets'] != null
            ? List<Pet>.unmodifiable(
                (json['ownedPets'] as List).map(
                  (x) => Pet.fromJson(x as Map<String, dynamic>),
                ),
              )
            : const [],
      );

  static List<AssetQuantity> _entriesFrom(Object? json) => json is List
      ? List<AssetQuantity>.from(json.map(AssetQuantity.tryFromJson).nonNulls)
      : <AssetQuantity>[];

  Map<String, dynamic> toJson() => {
    "ownedEquipments": ownedEquipments?.map((e) => e.toJson()).toList(),
    "ownedItems": ownedItems?.map((e) => e.toJson()).toList(),
    "activeSpells": activeSpells?.map((e) => e.toJson()).toList(),
    "wearedEquipment": wearedEquipment?.toJson(),
    "pet": pet?.id,
    "ownedPets": ownedPets.map((p) => p.id).toList(),
  };

  @override
  List<Object?> get props => [
    ownedItems,
    ownedEquipments,
    wearedEquipment,
    activeSpells,
    pet,
    ownedPets,
  ];
}
