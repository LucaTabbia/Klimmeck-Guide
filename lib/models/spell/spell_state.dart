import 'package:equatable/equatable.dart';
import 'package:klimmeck_guide/models/spell.dart';

/// Stato di una magia conosciuta: la magia di catalogo, gli usi rimasti, gli
/// istanti UTC, crescenti, in cui ogni uso torna e se è equipaggiata. Dalla
/// BE Phase 19 (D-05) la voce è l'unica fonte di una magia conosciuta;
/// `active` si legge dal backend, non si deriva da altre liste.
class SpellState extends Equatable {
  const SpellState({
    required this.spell,
    required this.usages,
    required this.recoveries,
    this.active = false,
  });

  factory SpellState.fromJson(Map<String, dynamic> json) => SpellState(
    spell: Spell.fromJson(json['spell'] as Map<String, dynamic>),
    usages: (json['usages'] as num).toInt(),
    recoveries: List<DateTime>.unmodifiable(
      (json['recoveries'] as List)
          .map((value) => DateTime.parse(value as String).toUtc())
          .toList()
        ..sort(),
    ),
    active: json['active'] == true,
  );

  /// Confine di parsing: una voce malformata vale `null`, lo status sopravvive (D-03).
  static SpellState? tryFromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    try {
      return SpellState.fromJson(json);
    } on Object {
      return null;
    }
  }

  final Spell spell;
  final int usages;
  final List<DateTime> recoveries;
  final bool active;

  String get spellId => spell.id;

  Map<String, dynamic> toJson() => {
    'spell': spell.toJson(),
    'usages': usages,
    'recoveries': recoveries
        .map((instant) => instant.toUtc().toIso8601String())
        .toList(),
    'active': active,
  };

  @override
  List<Object?> get props => [spell, usages, recoveries, active];
}
