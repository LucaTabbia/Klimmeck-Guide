import 'package:equatable/equatable.dart';
import 'package:klimmeck_guide/models/spell.dart';

/// Magia usata durante la quest; `spell` è `null` se la magia non esiste più.
class SpellUsage extends Equatable {
  const SpellUsage({required this.usages, required this.spell});

  final int usages;
  final Spell? spell;

  factory SpellUsage.fromJson(Map<String, dynamic> json) {
    final spell = json['spell'];
    return SpellUsage(
      usages: (json['usages'] as num).toInt(),
      spell: spell is Map<String, dynamic> ? Spell.fromJson(spell) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'usages': usages,
    'spell': spell == null ? null : {'id': spell!.id, 'name': spell!.name},
  };

  @override
  List<Object?> get props => [usages, spell];
}
