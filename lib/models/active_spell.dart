import 'package:equatable/equatable.dart';
import 'package:klimmeck_guide/models/spell.dart';

class ActiveSpell extends Equatable {
  const ActiveSpell({required this.usages, required this.spell});

  final Spell? spell;
  final int? usages;

  factory ActiveSpell.fromJson(Map<String, dynamic> json) => ActiveSpell(
    spell: json['spell'] != null ? Spell.fromJson(json['spell']) : null,
    usages: (json['usages'] as num?)?.toInt(),
  );

  Map<String, dynamic> toJson() => {'usages': usages, 'spell': spell?.toJson()};

  ActiveSpell copyWith({Spell? spell, int? usages}) {
    return ActiveSpell(
      spell: spell ?? this.spell,
      usages: usages ?? this.usages,
    );
  }

  @override
  List<Object?> get props => [usages, spell];
}
