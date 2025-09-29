import 'package:klimmeck_guide/models/energy_damage.dart';

import 'enums/use_type.dart';

class Spell {
  Spell({
    required this.id,
    required this.name,
    required this.useType,
    required this.energyDamage,
    required this.requiredLearnTime,
    required this.minXpToLearn,
    required this.recoveryTime,
    required this.maxUsages,
  });

  final String id;
  final String? name;
  final UseType? useType;
  final EnergyDamage? energyDamage;
  final int? requiredLearnTime;
  final int? minXpToLearn;
  final int? recoveryTime;
  final int? maxUsages;

  factory Spell.fromJson(Map<String, dynamic> json) => Spell(
    id: json['id'],
    name: json['name'],
    useType: json['useType'] != null ? UseType.values.byName(json['useType']) : null,
    energyDamage: json['energyDamage'] != null ? EnergyDamage.fromJson(json['energyDamage']) : null,
    requiredLearnTime: (json['requiredLearnTime'] as num?)?.toInt(),
    minXpToLearn: (json['minXpToLearn'] as num?)?.toInt(),
    recoveryTime: (json['recoveryTime'] as num?)?.toInt(),
    maxUsages: (json['maxUsages'] as num?)?.toInt(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'useType': useType?.name,
    'energyDamage': energyDamage?.toJson(),
    'minXpToLearn': minXpToLearn,
    'requiredLearnTime': requiredLearnTime,
  };
}
