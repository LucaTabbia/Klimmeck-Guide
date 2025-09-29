import 'dart:io';

import 'package:klimmeck_guide/models/damages.dart';
import 'package:klimmeck_guide/models/enums/damage_type.dart';
import 'package:klimmeck_guide/models/enums/energy_type.dart';
import 'package:klimmeck_guide/models/spell.dart';
import 'package:latlong2/latlong.dart';

import 'lore.dart';

class Enemy {
  Enemy({
    required this.id,
    required this.locations,
    required this.xp,
    required this.energyWeaknesses,
    required this.baseWeaknesses,
    required this.name,
    required this.spells,
    required this.lifePoints,
    required this.relatedLore,
    required this.imagePath,
    required this.damages,
  });

  final String id;
  final List<LatLng>? locations;
  final String? name;
  final Damages? damages;
  final List<EnergyType>? energyWeaknesses;
  final List<DamageType>? baseWeaknesses;
  final List<Lore>? relatedLore;
  final int? xp;
  final String? imagePath;
  List<Spell>? spells = const [];
  int? lifePoints;

  File? get image => imagePath != null ? File(imagePath!) : null;

  factory Enemy.fromJson(Map<String, dynamic> json) => Enemy(
    id: json["id"],
    name: json["name"],
    locations: json['locations'] != null
        ? List<LatLng>.from(json['locations'].map((x) => LatLng(x['latitude'], x['longitude'])))
        : [],
    energyWeaknesses: json['energyWeaknesses'] != null
        ? List<EnergyType>.from(json["energyWeaknesses"].map((x) => EnergyType.values.byName(x)))
        : [],
    baseWeaknesses: json['baseWeaknesses'] != null
        ? List<DamageType>.from(json["baseWeaknesses"].map((x) => DamageType.values.byName(x)))
        : [],
    relatedLore: json['relatedLore'] != null
        ? List<Lore>.from(json['relatedLore'].map((x) => Lore.fromJson(x)))
        : [],
    xp: json["xp"]?.toInt(),
    spells: json['spells'] != null
        ? List<Spell>.from(json['spells'].map((x) => Spell.fromJson(x)))
        : [],
    lifePoints: json["lifePoints"]?.toInt(),
    imagePath: json["imagePath"],
    damages: json["damages"] != null ? Damages.fromJson(json["damages"]) : null,
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "damages": damages?.toJson(),
    "locations": locations?.map((s) => {"latitude": s.latitude, "longitude": s.longitude}).toList(),
    "energyWeaknesses": energyWeaknesses?.map((s) => s.name).toList(),
    "baseWeaknesses": baseWeaknesses?.map((s) => s.name).toList(),
    "relatedLore": relatedLore?.map((s) => s.id).toList(),
    "xp": xp,
    "spells": spells?.map((s) => s.id).toList(),
    "lifePoints": lifePoints,
    "imagePath": imagePath,
  };
}
