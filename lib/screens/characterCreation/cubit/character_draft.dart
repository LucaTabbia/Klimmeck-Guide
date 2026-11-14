import 'package:equatable/equatable.dart';
import 'package:klimmeck_guide/models/character/race_traits.dart';
import 'package:klimmeck_guide/models/enums/class_type.dart';
import 'package:klimmeck_guide/models/enums/pronoun_type.dart';
import 'package:klimmeck_guide/models/enums/race_type.dart';
import 'package:klimmeck_guide/models/enums/sex_type.dart';
import 'package:klimmeck_guide/models/request/create_character_request.dart';
import 'package:klimmeck_guide/utils/name_rules.dart' as name_rules;

export 'package:klimmeck_guide/utils/name_rules.dart' show NameError;

enum AgeError { required, notANumber, outOfRange }

/// Bozza della scheda personaggio. Le regole sono solo UX: il backend resta
/// l'autorità (D-23) e usa le stesse soglie (BE 2.1 D-05/D-07/D-19).
class CharacterDraft extends Equatable {
  const CharacterDraft({
    this.sex,
    this.name = '',
    this.pronoun,
    this.race,
    this.classType,
    this.ageText = '',
    this.background = '',
  });

  static const int nameMinLength = name_rules.nameMinLength;
  static const int nameMaxLength = name_rules.nameMaxLength;
  static const int backgroundMaxLength = 500;

  final SexType? sex;
  final String name;
  final PronounType? pronoun;
  final RaceType? race;
  final ClassType? classType;
  final String ageText;
  final String background;

  String get normalizedName => name_rules.normalizedNameOf(name);
  int? get age => int.tryParse(ageText.trim());
  String get trimmedBackground => background.trim();

  /// UTF-16 units, come il `.length` del backend.
  bool get isBackgroundTooLong =>
      trimmedBackground.length > backgroundMaxLength;

  name_rules.NameError? get nameError => name_rules.nameErrorOf(name);

  /// Null senza tratti: il campo età resta disabilitato finché non esiste una
  /// razza con tratti noti (D-10).
  AgeError? ageErrorFor(RaceTraits? traits) {
    if (traits == null) return null;
    if (ageText.trim().isEmpty) return AgeError.required;
    final parsed = age;
    if (parsed == null) return AgeError.notANumber;
    return traits.allows(parsed) ? null : AgeError.outOfRange;
  }

  bool isCompleteFor(Map<RaceType, RaceTraits> raceTraits) {
    final selectedRace = race;
    if (sex == null ||
        pronoun == null ||
        selectedRace == null ||
        classType == null) {
      return false;
    }
    final traits = raceTraits[selectedRace];
    return traits != null &&
        nameError == null &&
        ageErrorFor(traits) == null &&
        !isBackgroundTooLong;
  }

  /// Da chiamare solo se [isCompleteFor] è vero.
  CreateCharacterRequest toRequest({String? imagePath}) =>
      CreateCharacterRequest(
        name: normalizedName,
        sex: sex!,
        pronoun: pronoun!,
        race: race!,
        classType: classType!,
        age: age!,
        background: trimmedBackground,
        imagePath: imagePath,
      );

  CharacterDraft copyWith({
    SexType? sex,
    String? name,
    PronounType? pronoun,
    RaceType? race,
    ClassType? classType,
    String? ageText,
    String? background,
  }) => CharacterDraft(
    sex: sex ?? this.sex,
    name: name ?? this.name,
    pronoun: pronoun ?? this.pronoun,
    race: race ?? this.race,
    classType: classType ?? this.classType,
    ageText: ageText ?? this.ageText,
    background: background ?? this.background,
  );

  @override
  List<Object?> get props => [
    sex,
    name,
    pronoun,
    race,
    classType,
    ageText,
    background,
  ];
}
