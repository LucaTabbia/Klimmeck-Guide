import 'package:klimmeck_guide/models/enums/injury_type.dart';
import 'package:klimmeck_guide/models/spell.dart';
import 'package:latlong2/latlong.dart';

import '../coins.dart';
import '../enums/title_type.dart';

class CharacterStatus {
  CharacterStatus({
    required this.location,
    required this.xp,
    required this.spells,
    required this.coins,
    required this.injuries,
    required this.currentLifePoints,
    required this.maxLifePoints,
    required this.title,
  });

  int? xp;
  LatLng? location;
  TitleType? title;
  List<InjuryType>? injuries = const [];
  List<Spell>? spells = const [];
  Coins? coins;
  int? currentLifePoints;
  int? maxLifePoints;

  factory CharacterStatus.fromJson(Map<String, dynamic> json) => CharacterStatus(
    location: json['location'] != null
        ? LatLng(json['location']['latitude'], json['location']['longitude'])
        : null,
    xp: json["xp"]?.toInt(),
    coins: json['coins'] != null ? Coins.fromJson(json["coins"]) : null,
    spells: json['spells'] != null
        ? List<Spell>.from(json['spells'].map((x) => Spell.fromJson(x)))
        : [],
    injuries: json['injuries'] != null
        ? List<InjuryType>.from(json['injuries'].map((x) => InjuryType.values.byName(x)))
        : [],
    currentLifePoints: json["currentLifePoints"]?.toInt(),
    maxLifePoints: json["maxLifePoints"]?.toInt(),
    title: json['title'] != null ? TitleType.values.byName(json['title']) : null,
  );

  Map<String, dynamic> toJson() => {
    "location": location != null
        ? {"latitude": location!.latitude, "longitude": location!.longitude}
        : null,
    "xp": xp,
    "spells": spells?.map((s) => s.id).toList(),
    "coins": coins?.toJson(),
    "injuries": injuries?.map((e) => e.name).toList(),
    "currentLifePoints": currentLifePoints,
    "maxLifePoints": maxLifePoints,
    "title": title?.name,
  };
}
