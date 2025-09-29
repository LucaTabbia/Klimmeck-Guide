import 'package:klimmeck_guide/models/spell.dart';

class ActiveSpell {
  ActiveSpell({required this.usages, required this.spell});

  final Spell? spell;
  final int? usages;

  factory ActiveSpell.fromJson(Map<String, dynamic> json) => ActiveSpell(
    spell: json['spell'] != null ? Spell.fromJson(json['spell']) : null,
    usages: (json['minXpToLearn'] as num?)?.toInt(),
  );

  Map<String, dynamic> toJson() => {'usages': usages, 'spell': spell?.toJson()};
}
