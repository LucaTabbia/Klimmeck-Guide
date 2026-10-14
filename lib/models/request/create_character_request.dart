import 'package:equatable/equatable.dart';
import 'package:klimmeck_guide/models/enums/class_type.dart';
import 'package:klimmeck_guide/models/enums/pronoun_type.dart';
import 'package:klimmeck_guide/models/enums/race_type.dart';
import 'package:klimmeck_guide/models/enums/sex_type.dart';

class CreateCharacterRequest extends Equatable {
  const CreateCharacterRequest({
    required this.name,
    required this.sex,
    required this.pronoun,
    required this.race,
    required this.classType,
    required this.age,
    this.background = '',
    this.imagePath,
  });

  final String name;
  final SexType sex;
  final PronounType pronoun;
  final RaceType race;
  final ClassType classType;
  final int age;
  final String background;
  final String? imagePath;

  Map<String, dynamic> toJson() => {
    'name': name,
    'sex': sex.name,
    'pronoun': pronoun.name,
    'race': race.name,
    'classType': classType.name,
    'age': age,
    if (background.isNotEmpty) 'background': background,
    if (imagePath != null) 'imagePath': imagePath,
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
