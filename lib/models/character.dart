import 'dart:io';

import 'package:klimmeck_guide/models/enums/injury_type.dart';
import 'package:klimmeck_guide/models/enums/race_type.dart';
import 'package:klimmeck_guide/models/equipment.dart';
import 'package:klimmeck_guide/models/equipment_item.dart';
import 'package:klimmeck_guide/models/loot_item.dart';
import 'package:klimmeck_guide/models/pet.dart';
import 'package:klimmeck_guide/models/spell.dart';
import 'package:latlong2/latlong.dart';

import 'enums/class_type.dart';

class Character {
  Character({
    required this.id,
    required this.imagePath,
    required this.name,
    required this.race,
    required this.location,
    required this.classType,
    required this.age,
    required this.xp,
    required this.background,
    required this.spells,
    required this.ownedEquipment,
    required this.wearedEquipment,
    required this.coins,
    required this.injuries,
    required this.currentLifePoints,
    required this.maxLifePoints,
    required this.pet,
    required this.ownedLoot,
  });

  final String id;
  final String? imagePath;
  final String name;
  final RaceType race;
  final ClassType classType;
  final int age;
  final int xp;
  final String background;
  LatLng location;
  List<InjuryType> injuries = const [];
  List<Spell> spells = const [];
  List<EquipmentItem> ownedEquipment = const [];
  Equipment wearedEquipment;
  int coins;
  int currentLifePoints;
  int maxLifePoints;
  Pet? pet;
  List<LootItem> ownedLoot;

  File? get image => imagePath != null ? File(imagePath!) : null;

  factory Character.fromJson(Map<String, dynamic> json) => Character(
    id: json["id"],
    name: json["name"],
    race: RaceType.values.byName(json['race']),
    classType: ClassType.values.byName(json['classType']),
    location: LatLng(json['location']['latitude'], json['location']['longitude']),
    age: json["age"].toInt(),
    xp: json["xp"].toInt(),
    coins: json["coins"].toInt(),
    background: json["background"],
    spells: List<Spell>.from(json['spells'].map((x) => Spell.fromJson(x))),
    ownedEquipment: List<EquipmentItem>.from(
      json['ownedEquipment'].map((x) => EquipmentItem.fromJson(x)),
    ),
    wearedEquipment: Equipment.fromJson(json['wearedEquipment']),
    imagePath: json["imagePath"],
    injuries: List<InjuryType>.from(json['injuries'].map((x) => InjuryType.values.byName(x))),
    currentLifePoints: json["currentLifePoints"].toInt(),
    maxLifePoints: json["maxLifePoints"].toInt(),
    pet: Pet.fromJson(json['pet']),
    ownedLoot: List<LootItem>.from(json['ownedLoot'].map((x) => LootItem.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "race": race.name,
    "classType": classType.name,
    "age": age,
    "location": location.toJson(),
    "xp": xp,
    "background": background,
    "spells": spells.map((s) => s.id).toList(),
    "ownedEquipment": ownedEquipment.map((s) => s.id).toList(),
    "wearedEquipment": wearedEquipment.toJson(),
    "imagePath": imagePath,
    "coins": coins,
    "injuries": injuries.map((e) => e.name).toList(),
    "currentLifePoints": currentLifePoints,
    "maxLifePoints": maxLifePoints,
    "pet": pet?.id,
    "ownedLoot": ownedLoot.map((s) => s.id).toList(),
  };
}
