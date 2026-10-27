import 'package:equatable/equatable.dart';

/// Stato di una magia conosciuta (BE 9.1, D-02): usi rimasti e istanti UTC,
/// crescenti, in cui ogni uso torna. Sopravvive a equip e disequip (D-01).
class SpellState extends Equatable {
  const SpellState({
    required this.spellId,
    required this.usages,
    required this.recoveries,
  });

  factory SpellState.fromJson(Map<String, dynamic> json) => SpellState(
    spellId: (json['spell'] as Map<String, dynamic>)['id'] as String,
    usages: (json['usages'] as num).toInt(),
    recoveries: List<DateTime>.unmodifiable(
      (json['recoveries'] as List)
          .map((value) => DateTime.parse(value as String).toUtc())
          .toList()
        ..sort(),
    ),
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

  final String spellId;
  final int usages;
  final List<DateTime> recoveries;

  Map<String, dynamic> toJson() => {
    'spell': {'id': spellId},
    'usages': usages,
    'recoveries': recoveries
        .map((instant) => instant.toUtc().toIso8601String())
        .toList(),
  };

  @override
  List<Object?> get props => [spellId, usages, recoveries];
}
