import 'package:equatable/equatable.dart';
import 'package:klimmeck_guide/models/character/awaiting_aid.dart';
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
    this.awaitingAid,
    this.unlockedLore = const [],
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

  /// Ferito in attesa di soccorso (D-16); `null` = libero o campo assente.
  final AwaitingAid? awaitingAid;

  /// Id delle lore sbloccate dal personaggio (BE Phase 16, D-01): servono solo
  /// a sapere quando e cosa è cambiato; l'ordine non conta.
  final List<String> unlockedLore;

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
        injuries: _injuriesFrom(json['injuries']),
        currentLifePoints: json["currentLifePoints"]?.toInt(),
        maxLifePoints: json["maxLifePoints"]?.toInt(),
        level: json["level"]?.toInt(),
        title: json['title'] != null
            ? TitleType.values.byName(json['title'])
            : null,
        maxActiveSpells: json['maxActiveSpells']?.toInt(),
        activeTravel: ActiveTravel.tryFromJson(json['activeTravel']),
        spellStates: _spellStatesFrom(json['spellStates']),
        awaitingAid: AwaitingAid.tryFromJson(json['awaitingAid']),
        unlockedLore: _unlockedLoreFrom(json['unlockedLore']),
      );

  static List<SpellState>? _spellStatesFrom(Object? json) {
    if (json is! List) return null;
    return List<SpellState>.unmodifiable(
      json.map(SpellState.tryFromJson).whereType<SpellState>(),
    );
  }

  static List<String> _unlockedLoreFrom(Object? json) {
    if (json is! List) return const [];
    return List<String>.unmodifiable(json.whereType<String>());
  }

  /// Un nome di ferita che il client non conosce è scartato (quick 261109-inj2):
  /// un BE più nuovo non rompe mai la lettura del personaggio.
  static List<InjuryType> _injuriesFrom(Object? json) {
    if (json is! List) return const [];
    final byName = InjuryType.values.asNameMap();
    return List<InjuryType>.unmodifiable(
      json.map((name) => byName[name]).nonNulls,
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
    "awaitingAid": awaitingAid?.toJson(),
    "unlockedLore": unlockedLore,
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
      awaitingAid: awaitingAid,
      unlockedLore: unlockedLore,
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
    awaitingAid,
    unlockedLore,
  ];
}
