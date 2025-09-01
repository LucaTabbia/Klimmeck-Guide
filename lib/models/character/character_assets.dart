import 'package:klimmeck_guide/models/equipment.dart';
import 'package:klimmeck_guide/models/equipment_quantity.dart';
import 'package:klimmeck_guide/models/pet.dart';

class CharacterAssets {
  CharacterAssets({required this.ownedItems, required this.wearedEquipment, required this.pet});

  List<AssetQuantity>? ownedItems = const [];
  Equipment? wearedEquipment;
  Pet? pet;

  factory CharacterAssets.fromJson(Map<String, dynamic> json) => CharacterAssets(
    ownedItems: json['ownedItems'] != null
        ? List<AssetQuantity>.from(json['ownedItems'].map((x) => AssetQuantity.fromJson(x)))
        : [],
    wearedEquipment: json['wearedEquipment'] != null
        ? Equipment.fromJson(json['wearedEquipment'])
        : null,
    pet: json['pet'] != null ? Pet.fromJson(json['pet']) : null,
  );

  Map<String, dynamic> toJson() => {
    "ownedItems": ownedItems,
    "wearedEquipment": wearedEquipment?.toJson(),
    "pet": pet?.id,
  };
}
