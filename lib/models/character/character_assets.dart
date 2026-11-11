import 'package:equatable/equatable.dart';
import 'package:klimmeck_guide/models/active_spell.dart';
import 'package:klimmeck_guide/models/asset_quantity.dart';
import 'package:klimmeck_guide/models/equipment.dart';
import 'package:klimmeck_guide/models/owned_pet.dart';
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
  final List<OwnedPet> ownedPets;

  /// Compagni a catalogo dei posseduti, nell'ordine servito (negozio, slot).
  List<Pet> get ownedCatalogPets => [for (final owned in ownedPets) owned.pet];

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
        ownedPets: _ownedPetsFrom(json['ownedPets']),
      );

  static List<OwnedPet> _ownedPetsFrom(Object? json) => json is List
      ? List<OwnedPet>.unmodifiable(json.map(OwnedPet.tryFromJson).nonNulls)
      : const [];

  static List<AssetQuantity> _entriesFrom(Object? json) => json is List
      ? List<AssetQuantity>.from(json.map(AssetQuantity.tryFromJson).nonNulls)
      : <AssetQuantity>[];

  Map<String, dynamic> toJson() => {
    "ownedEquipments": ownedEquipments?.map((e) => e.toJson()).toList(),
    "ownedItems": ownedItems?.map((e) => e.toJson()).toList(),
    "activeSpells": activeSpells?.map((e) => e.toJson()).toList(),
    "wearedEquipment": wearedEquipment?.toJson(),
    "pet": pet?.id,
    "ownedPets": [for (final owned in ownedPets) owned.toJson()],
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
