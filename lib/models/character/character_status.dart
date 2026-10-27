import 'package:equatable/equatable.dart';
import 'package:klimmeck_guide/models/enums/injury_type.dart';
import 'package:klimmeck_guide/models/point_of_interest.dart';
import 'package:klimmeck_guide/models/spell.dart';
import 'package:klimmeck_guide/models/spell/spell_state.dart';
import 'package:klimmeck_guide/models/travel/active_travel.dart';

import '../coins.dart';
import '../enums/title_type.dart';

class CharacterStatus extends Equatable {
  const CharacterStatus({
    required this.location,
    required this.xp,
    required this.spells,
    required this.coins,
    required this.injuries,
    required this.currentLifePoints,
    required this.maxLifePoints,
    required this.title,
    required this.level,
    required this.maxActiveSpells,
    this.activeTravel,
    this.spellStates,
  });

  final int? xp;
  final int? level;
  final PointOfInterest? location;
  final TitleType? title;
  final List<InjuryType>? injuries;
  final List<Spell>? spells;
  final Coins? coins;
  final int? currentLifePoints;
  final int? maxLifePoints;
  final int? maxActiveSpells;

  /// Viaggio in corso (BE Phase 8); `null` = fermo. Un viaggio malformato vale `null`.
  final ActiveTravel? activeTravel;

  /// Stato per magia conosciuta (BE 9.1); `null` = campo assente (backend pre-9.1 o fragment non ancora esteso, D-03).
  final List<SpellState>? spellStates;

  factory CharacterStatus.fromJson(Map<String, dynamic> json) =>
      CharacterStatus(
        location: json['location'] != null
            ? PointOfInterest.fromJson(json['location'])
            : null,
        xp: json["xp"]?.toInt(),
        coins: json['coins'] != null ? Coins.fromJson(json["coins"]) : null,
        spells: json['spells'] != null
            ? List<Spell>.from(json['spells'].map((x) => Spell.fromJson(x)))
            : [],
        injuries: json['injuries'] != null
            ? List<InjuryType>.from(
                json['injuries'].map((x) => InjuryType.values.byName(x)),
              )
            : [],
        currentLifePoints: json["currentLifePoints"]?.toInt(),
        maxLifePoints: json["maxLifePoints"]?.toInt(),
        level: json["level"]?.toInt(),
        title: json['title'] != null
            ? TitleType.values.byName(json['title'])
            : null,
        maxActiveSpells: json['maxActiveSpells']?.toInt(),
        activeTravel: ActiveTravel.tryFromJson(json['activeTravel']),
        spellStates: _spellStatesFrom(json['spellStates']),
      );

  static List<SpellState>? _spellStatesFrom(Object? json) {
    if (json is! List) return null;
    return List<SpellState>.unmodifiable(
      json.map(SpellState.tryFromJson).whereType<SpellState>(),
    );
  }

  Map<String, dynamic> toJson() => {
    "location": location?.toJson(),
    "xp": xp,
    "level": level,
    "spells": spells?.map((s) => s.id).toList(),
    "coins": coins?.toJson(),
    "injuries": injuries?.map((e) => e.name).toList(),
    "currentLifePoints": currentLifePoints,
    "maxLifePoints": maxLifePoints,
    "title": title?.name,
    "maxActiveSpells": maxActiveSpells,
    "activeTravel": activeTravel?.toJson(),
    "spellStates": spellStates?.map((state) => state.toJson()).toList(),
  };

  CharacterStatus copyWith({
    PointOfInterest? location,
    int? xp,
    int? level,
    TitleType? title,
    List<InjuryType>? injuries,
    List<Spell>? spells,
    Coins? coins,
    int? currentLifePoints,
    int? maxLifePoints,
    int? maxActiveSpells,
  }) {
    return CharacterStatus(
      location: location ?? this.location,
      xp: xp ?? this.xp,
      level: level ?? this.level,
      title: title ?? this.title,
      injuries: injuries ?? this.injuries,
      spells: spells ?? this.spells,
      coins: coins ?? this.coins,
      currentLifePoints: currentLifePoints ?? this.currentLifePoints,
      maxLifePoints: maxLifePoints ?? this.maxLifePoints,
      maxActiveSpells: maxActiveSpells ?? this.maxActiveSpells,
      activeTravel: activeTravel,
      spellStates: spellStates,
    );
  }

  @override
  List<Object?> get props => [
    location,
    xp,
    level,
    title,
    injuries,
    spells,
    coins,
    currentLifePoints,
    maxLifePoints,
    maxActiveSpells,
    activeTravel,
    spellStates,
  ];
}
