import 'dart:io';

import 'package:klimmeck_guide/models/enums/pronoun_type.dart';
import 'package:klimmeck_guide/models/enums/race_type.dart';
import 'package:klimmeck_guide/models/enums/sex_type.dart';

import '../enums/class_type.dart';

class CharacterInfos {
  CharacterInfos({
    required this.sex,
    required this.imagePath,
    required this.name,
    required this.pronoun,
    required this.race,
    required this.classType,
    required this.age,
    required this.background,
  });

  final String? imagePath;
  final SexType? sex;
  final String? name;
  final RaceType? race;
  final PronounType? pronoun;
  final ClassType? classType;
  final int? age;
  final String? background;

  File? get image => imagePath != null ? File(imagePath!) : null;

  factory CharacterInfos.fromJson(Map<String, dynamic> json) => CharacterInfos(
    name: json["name"],
    sex: json['sex'] != null ? SexType.values.byName(json['sex']) : null,
    race: json['race'] != null ? RaceType.values.byName(json['race']) : null,
    classType: json['classType'] != null ? ClassType.values.byName(json['classType']) : null,
    age: json["age"]?.toInt(),
    background: json["background"],
    imagePath: json["imagePath"],
    pronoun: json['pronoun'] != null ? PronounType.values.byName(json['pronoun']) : null,
  );

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
}
