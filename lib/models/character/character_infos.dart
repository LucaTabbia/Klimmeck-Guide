import 'package:equatable/equatable.dart';
import 'package:klimmeck_guide/models/enums/pronoun_type.dart';
import 'package:klimmeck_guide/models/enums/race_type.dart';
import 'package:klimmeck_guide/models/enums/sex_type.dart';

import '../enums/class_type.dart';

class CharacterInfos extends Equatable {
  const CharacterInfos({
    required this.sex,
    required this.imagePath,
    required this.name,
    required this.pronoun,
    required this.race,
    required this.classType,
    required this.age,
    this.background = const [],
  });

  final String? imagePath;
  final SexType? sex;
  final String? name;
  final RaceType? race;
  final PronounType? pronoun;
  final ClassType? classType;
  final int? age;

  /// Voci del background in ordine d'arrivo (la prima è la storia scritta
  /// alla creazione); vuota se il campo è assente.
  final List<String> background;

  factory CharacterInfos.fromJson(Map<String, dynamic> json) => CharacterInfos(
    name: json["name"],
    sex: json['sex'] != null ? SexType.values.byName(json['sex']) : null,
    race: json['race'] != null ? RaceType.values.byName(json['race']) : null,
    classType: json['classType'] != null
        ? ClassType.values.byName(json['classType'])
        : null,
    age: json["age"]?.toInt(),
    background: _backgroundFrom(json["background"]),
    imagePath: json["imagePath"],
    pronoun: json['pronoun'] != null
        ? PronounType.values.byName(json['pronoun'])
        : null,
  );

  static List<String> _backgroundFrom(Object? json) {
    if (json is! List) return const [];
    return List<String>.unmodifiable(json.whereType<String>());
  }

  Map<String, dynamic> toJson() => {
    "name": name,
    "sex": sex?.name,
    "pronoun": pronoun?.name,
    "race": race?.name,
    "classType": classType?.name,
    "age": age,
    "background": background,
    "imagePath": imagePath,
  };

  @override
  List<Object?> get props => [
    name,
    sex,
    pronoun,
    race,
    classType,
    age,
    background,
    imagePath,
  ];
}
