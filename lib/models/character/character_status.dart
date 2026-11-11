import 'package:equatable/equatable.dart';
import 'package:klimmeck_guide/models/character/awaiting_aid.dart';
import 'package:klimmeck_guide/models/enums/injury_type.dart';
import 'package:klimmeck_guide/models/point_of_interest.dart';
import 'package:klimmeck_guide/models/spell/spell_state.dart';
import 'package:klimmeck_guide/models/travel/active_travel.dart';

import '../coins.dart';
import '../enums/title_type.dart';

class CharacterStatus extends Equatable {
  const CharacterStatus({
    required this.location,
    required this.xp,
    required this.coins,
    required this.injuries,
    required this.currentLifePoints,
    required this.maxLifePoints,
    required this.title,
    required this.level,
    required this.maxActiveSpells,
    this.activeTravel,
    this.spellStates = const [],
    this.awaitingAid,
    this.unlockedLore = const [],
    this.potionRecoveryUntil,
    this.imprisonedUntil,
  });

  final int? xp;
  final int? level;
  final PointOfInterest? location;
  final TitleType? title;
  final List<InjuryType>? injuries;
  final Coins? coins;
  final int? currentLifePoints;
  final int? maxLifePoints;
  final int? maxActiveSpells;

  /// Viaggio in corso (BE Phase 8); `null` = fermo. Un viaggio malformato vale `null`.
  final ActiveTravel? activeTravel;

  /// Unica fonte delle magie conosciute (BE Phase 19, D-05): magia, usi,
  /// ricariche e `active` per voce; vuota se il campo è assente.
  final List<SpellState> spellStates;

  /// Ferito in attesa di soccorso (D-16); `null` = libero o campo assente.
  final AwaitingAid? awaitingAid;

  /// Id delle lore sbloccate dal personaggio (BE Phase 16, D-01): servono solo
  /// a sapere quando e cosa è cambiato; l'ordine non conta.
  final List<String> unlockedLore;

  /// Fine della ricarica delle pozioni (BE Phase 18, D-12), istante UTC del
  /// server; `null` = nessuna ricarica in corso o campo assente.
  final DateTime? potionRecoveryUntil;

  /// Fine della prigione (quick 261110-cgd), istante UTC del server; `null` o
  /// passata = libero. Nessuno sweep la azzera: il client si libera da sé.
  final DateTime? imprisonedUntil;

  factory CharacterStatus.fromJson(Map<String, dynamic> json) =>
      CharacterStatus(
        location: json['location'] != null
            ? PointOfInterest.fromJson(json['location'])
            : null,
        xp: json["xp"]?.toInt(),
        coins: json['coins'] != null ? Coins.fromJson(json["coins"]) : null,
        injuries: injuryTypesFrom(json['injuries']),
        currentLifePoints: json["currentLifePoints"]?.toInt(),
        maxLifePoints: json["maxLifePoints"]?.toInt(),
        level: json["level"]?.toInt(),
        title: TitleType.values.asNameMap()[json['title']],
        maxActiveSpells: json['maxActiveSpells']?.toInt(),
        activeTravel: ActiveTravel.tryFromJson(json['activeTravel']),
        spellStates: _spellStatesFrom(json['spellStates']),
        awaitingAid: AwaitingAid.tryFromJson(json['awaitingAid']),
        unlockedLore: _unlockedLoreFrom(json['unlockedLore']),
        potionRecoveryUntil: _instantOrNull(json['potionRecoveryUntil']),
        imprisonedUntil: _instantOrNull(json['imprisonedUntil']),
      );

  static List<SpellState> _spellStatesFrom(Object? json) {
    if (json is! List) return const [];
    return List<SpellState>.unmodifiable(
      json.map(SpellState.tryFromJson).whereType<SpellState>(),
    );
  }

  static List<String> _unlockedLoreFrom(Object? json) {
    if (json is! List) return const [];
    return List<String>.unmodifiable(json.whereType<String>());
  }

  /// Una data illeggibile vale `null`: il personaggio sopravvive.
  static DateTime? _instantOrNull(Object? json) =>
      json is String ? DateTime.tryParse(json)?.toUtc() : null;

  Map<String, dynamic> toJson() => {
    "location": location?.toJson(),
    "xp": xp,
    "level": level,
    "coins": coins?.toJson(),
    "injuries": injuries?.map((e) => e.name).toList(),
    "currentLifePoints": currentLifePoints,
    "maxLifePoints": maxLifePoints,
    "title": title?.name,
    "maxActiveSpells": maxActiveSpells,
    "activeTravel": activeTravel?.toJson(),
    "spellStates": spellStates.map((state) => state.toJson()).toList(),
    "awaitingAid": awaitingAid?.toJson(),
    "unlockedLore": unlockedLore,
    "potionRecoveryUntil": potionRecoveryUntil?.toUtc().toIso8601String(),
    "imprisonedUntil": imprisonedUntil?.toUtc().toIso8601String(),
  };

  CharacterStatus copyWith({
    PointOfInterest? location,
    int? xp,
    int? level,
    TitleType? title,
    List<InjuryType>? injuries,
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
      coins: coins ?? this.coins,
      currentLifePoints: currentLifePoints ?? this.currentLifePoints,
      maxLifePoints: maxLifePoints ?? this.maxLifePoints,
      maxActiveSpells: maxActiveSpells ?? this.maxActiveSpells,
      activeTravel: activeTravel,
      spellStates: spellStates,
      awaitingAid: awaitingAid,
      unlockedLore: unlockedLore,
      potionRecoveryUntil: potionRecoveryUntil,
      imprisonedUntil: imprisonedUntil,
    );
  }

  @override
  List<Object?> get props => [
    location,
    xp,
    level,
    title,
    injuries,
    coins,
    currentLifePoints,
    maxLifePoints,
    maxActiveSpells,
    activeTravel,
    spellStates,
    awaitingAid,
    unlockedLore,
    potionRecoveryUntil,
    imprisonedUntil,
  ];
}
