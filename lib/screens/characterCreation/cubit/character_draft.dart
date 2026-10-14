import 'package:equatable/equatable.dart';
import 'package:klimmeck_guide/models/character/race_traits.dart';
import 'package:klimmeck_guide/models/enums/class_type.dart';
import 'package:klimmeck_guide/models/enums/pronoun_type.dart';
import 'package:klimmeck_guide/models/enums/race_type.dart';
import 'package:klimmeck_guide/models/enums/sex_type.dart';
import 'package:klimmeck_guide/models/request/create_character_request.dart';

enum NameError { required, tooShort, tooLong, invalidCharacters }

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

  static const int nameMinLength = 2;
  static const int nameMaxLength = 20;
  static const int backgroundMaxLength = 500;
  static final RegExp _nameCharset = RegExp(r"^[\p{L}'’\- ]+$", unicode: true);
  static final RegExp _letter = RegExp(r'\p{L}', unicode: true);
  static final RegExp _whitespaceRun = RegExp(r'\s+');

  final SexType? sex;
  final String name;
  final PronounType? pronoun;
  final RaceType? race;
  final ClassType? classType;
  final String ageText;
  final String background;

  String get normalizedName => name.trim().replaceAll(_whitespaceRun, ' ');
  int? get age => int.tryParse(ageText.trim());
  String get trimmedBackground => background.trim();

  /// UTF-16 units, come il `.length` del backend.
  bool get isBackgroundTooLong =>
      trimmedBackground.length > backgroundMaxLength;

  NameError? get nameError {
    final normalized = normalizedName;
    if (normalized.isEmpty) return NameError.required;
    if (normalized.length < nameMinLength) return NameError.tooShort;
    if (normalized.length > nameMaxLength) return NameError.tooLong;
    if (!_nameCharset.hasMatch(normalized) || !_letter.hasMatch(normalized)) {
      return NameError.invalidCharacters;
    }
    return null;
  }

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
