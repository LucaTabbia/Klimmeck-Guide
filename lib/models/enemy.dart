import 'package:equatable/equatable.dart';
import 'package:klimmeck_guide/models/damages.dart';
import 'package:klimmeck_guide/models/enums/poi_type.dart';
import 'package:klimmeck_guide/models/spell.dart';
import 'package:klimmeck_guide/models/weaknesses.dart';

import 'lore.dart';

class Enemy extends Equatable {
  const Enemy({
    required this.id,
    required this.locations,
    required this.xp,
    this.weaknesses = const Weaknesses(),
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
  final Weaknesses weaknesses;
  final List<Lore>? relatedLore;
  final int? xp;
  final String? imagePath;
  final List<Spell>? spells;
  final int? lifePoints;

  factory Enemy.fromJson(Map<String, dynamic> json) => Enemy(
    id: json["id"],
    name: json["name"],
    locations: poiTypesFrom(json['locations']),
    weaknesses: Weaknesses.fromJson(json['weaknesses']),
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
    "weaknesses": weaknesses.toJson(),
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
    Weaknesses? weaknesses,
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
      weaknesses: weaknesses ?? this.weaknesses,
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
    weaknesses,
    name,
    spells,
    lifePoints,
    relatedLore,
    imagePath,
    damages,
  ];
}
