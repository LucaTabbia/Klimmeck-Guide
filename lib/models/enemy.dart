import 'package:equatable/equatable.dart';
import 'package:klimmeck_guide/models/damages.dart';
import 'package:klimmeck_guide/models/enums/damage_type.dart';
import 'package:klimmeck_guide/models/enums/energy_type.dart';
import 'package:klimmeck_guide/models/enums/poi_type.dart';
import 'package:klimmeck_guide/models/spell.dart';

import 'lore.dart';

class Enemy extends Equatable {
  const Enemy({
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
  final List<PoiType>? locations;
  final String? name;
  final Damages? damages;
  final List<EnergyType>? energyWeaknesses;
  final List<DamageType>? baseWeaknesses;
  final List<Lore>? relatedLore;
  final int? xp;
  final String? imagePath;
  final List<Spell>? spells;
  final int? lifePoints;

  factory Enemy.fromJson(Map<String, dynamic> json) => Enemy(
    id: json["id"],
    name: json["name"],
    locations: json["locations"]?.map(
      (poiType) => PoiType.values.byName(poiType),
    ),
    energyWeaknesses: json['energyWeaknesses'] != null
        ? List<EnergyType>.from(
            json["energyWeaknesses"].map((x) => EnergyType.values.byName(x)),
          )
        : [],
    baseWeaknesses: json['baseWeaknesses'] != null
        ? List<DamageType>.from(
            json["baseWeaknesses"].map((x) => DamageType.values.byName(x)),
          )
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
    "locations": locations?.map((s) => s.name).toList(),
    "energyWeaknesses": energyWeaknesses?.map((s) => s.name).toList(),
    "baseWeaknesses": baseWeaknesses?.map((s) => s.name).toList(),
    "relatedLore": relatedLore?.map((s) => s.id).toList(),
    "xp": xp,
    "spells": spells?.map((s) => s.id).toList(),
    "lifePoints": lifePoints,
    "imagePath": imagePath,
  };

  Enemy copyWith({
    String? id,
    List<PoiType>? locations,
    String? name,
    Damages? damages,
    List<EnergyType>? energyWeaknesses,
    List<DamageType>? baseWeaknesses,
    List<Lore>? relatedLore,
    int? xp,
    String? imagePath,
    List<Spell>? spells,
    int? lifePoints,
  }) {
    return Enemy(
      id: id ?? this.id,
      locations: locations ?? this.locations,
      xp: xp ?? this.xp,
      energyWeaknesses: energyWeaknesses ?? this.energyWeaknesses,
      baseWeaknesses: baseWeaknesses ?? this.baseWeaknesses,
      name: name ?? this.name,
      spells: spells ?? this.spells,
      lifePoints: lifePoints ?? this.lifePoints,
      relatedLore: relatedLore ?? this.relatedLore,
      imagePath: imagePath ?? this.imagePath,
      damages: damages ?? this.damages,
    );
  }

  @override
  List<Object?> get props => [
    id,
    locations,
    xp,
    energyWeaknesses,
    baseWeaknesses,
    name,
    spells,
    lifePoints,
    relatedLore,
    imagePath,
    damages,
  ];
}
