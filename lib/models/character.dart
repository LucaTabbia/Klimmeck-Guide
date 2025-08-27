import 'dart:io';

import 'package:klimmeck_guide/models/enums/injury_type.dart';
import 'package:klimmeck_guide/models/enums/race_type.dart';
import 'package:klimmeck_guide/models/equipment.dart';
import 'package:klimmeck_guide/models/equipment_item.dart';
import 'package:klimmeck_guide/models/loot_item.dart';
import 'package:klimmeck_guide/models/pet.dart';
import 'package:klimmeck_guide/models/spell.dart';
import 'package:latlong2/latlong.dart';

import 'coins.dart';
import 'enums/class_type.dart';
import 'enums/title_type.dart';

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
    required this.title,
  });

  final String id;
  final String? imagePath;
  final String? name;
  final RaceType? race;
  final ClassType? classType;
  final int? age;
  final int? xp;
  final String? background;
  LatLng? location;
  TitleType? title;
  List<InjuryType>? injuries = const [];
  List<Spell>? spells = const [];
  List<EquipmentItem>? ownedEquipment = const [];
  Equipment? wearedEquipment;
  Coins? coins;
  int? currentLifePoints;
  int? maxLifePoints;
  Pet? pet;
  List<LootItem>? ownedLoot;

  File? get image => imagePath != null ? File(imagePath!) : null;

  factory Character.fromJson(Map<String, dynamic> json) => Character(
    id: json["id"],
    name: json["name"],
    race: json['race'] != null ? RaceType.values.byName(json['race']) : null,
    classType: json['classType'] != null ? ClassType.values.byName(json['classType']) : null,
    location: json['location'] != null
        ? LatLng(json['location']['latitude'], json['location']['longitude'])
        : null,
    age: json["age"]?.toInt(),
    xp: json["xp"]?.toInt(),
    coins: json['coins'] != null ? Coins.fromJson(json["coins"]) : null,
    background: json["background"],
    spells: json['spells'] != null
        ? List<Spell>.from(json['spells'].map((x) => Spell.fromJson(x)))
        : [],
    ownedEquipment: json['ownedEquipment'] != null
        ? List<EquipmentItem>.from(json['ownedEquipment'].map((x) => EquipmentItem.fromJson(x)))
        : [],
    wearedEquipment: json['wearedEquipment'] != null
        ? Equipment.fromJson(json['wearedEquipment'])
        : null,
    imagePath: json["imagePath"],
    injuries: json['injuries'] != null
        ? List<InjuryType>.from(json['injuries'].map((x) => InjuryType.values.byName(x)))
        : [],
    currentLifePoints: json["currentLifePoints"]?.toInt(),
    maxLifePoints: json["maxLifePoints"]?.toInt(),
    pet: json['pet'] != null ? Pet.fromJson(json['pet']) : null,
    ownedLoot: json['ownedLoot'] != null
        ? List<LootItem>.from(json['ownedLoot'].map((x) => LootItem.fromJson(x)))
        : [],
    title: json['title'] != null ? TitleType.values.byName(json['title']) : null,
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "race": race?.name,
    "classType": classType?.name,
    "age": age,
    "location": location != null
        ? {"latitude": location!.latitude, "longitude": location!.longitude}
        : null,
    "xp": xp,
    "background": background,
    "spells": spells?.map((s) => s.id).toList(),
    "ownedEquipment": ownedEquipment?.map((s) => s.id).toList(),
    "wearedEquipment": wearedEquipment?.toJson(),
    "imagePath": imagePath,
    "coins": coins?.toJson(),
    "injuries": injuries?.map((e) => e.name).toList(),
    "currentLifePoints": currentLifePoints,
    "maxLifePoints": maxLifePoints,
    "pet": pet?.id,
    "ownedLoot": ownedLoot?.map((s) => s.id).toList(),
    "title": title?.name,
  };
}
