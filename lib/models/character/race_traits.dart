import 'package:equatable/equatable.dart';
import 'package:klimmeck_guide/models/enums/race_type.dart';

class RaceTraits extends Equatable {
  const RaceTraits({
    required this.race,
    required this.minAge,
    required this.maxAge,
  });

  final RaceType race;
  final int minAge;
  final int maxAge;

  factory RaceTraits.fromJson(Map<String, dynamic> json) => RaceTraits(
    race: RaceType.values.byName(json['race'] as String),
    minAge: (json['minAge'] as num).toInt(),
    maxAge: (json['maxAge'] as num).toInt(),
  );

  /// Null per razze sconosciute all'app o payload malformati: il backend può
  /// aggiungere razze prima dell'app.
  static RaceTraits? tryFromJson(Map<String, dynamic> json) {
    try {
      return RaceTraits.fromJson(json);
    } on Object {
      // Parse boundary: ArgumentError (byName) e TypeError (cast) sono attesi.
      return null;
    }
  }

  Map<String, dynamic> toJson() => {
    'race': race.name,
    'minAge': minAge,
    'maxAge': maxAge,
  };

  bool allows(int age) => age >= minAge && age <= maxAge;

  @override
  List<Object?> get props => [race, minAge, maxAge];
}
