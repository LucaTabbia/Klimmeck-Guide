import 'package:equatable/equatable.dart';
import 'package:klimmeck_guide/models/energy_damage.dart';

import 'enums/use_type.dart';

class Spell extends Equatable {
  const Spell({
    required this.id,
    required this.name,
    required this.description,
    required this.useType,
    required this.energyDamage,
    required this.requiredLearnTime,
    required this.minXpToLearn,
    required this.recoveryTime,
    required this.maxUsages,
  });

  final String id;
  final String? name;
  final String? description;
  final UseType? useType;
  final EnergyDamage? energyDamage;
  final int? requiredLearnTime;
  final int? minXpToLearn;
  final int? recoveryTime;
  final int? maxUsages;

  factory Spell.fromJson(Map<String, dynamic> json) => Spell(
    id: json['id'],
    name: json['name'],
    description: json['description'],
    useType: json['useType'] != null
        ? UseType.values.byName(json['useType'])
        : null,
    energyDamage: json['energyDamage'] != null
        ? EnergyDamage.fromJson(json['energyDamage'])
        : null,
    requiredLearnTime: (json['requiredLearnTime'] as num?)?.toInt(),
    minXpToLearn: (json['minXpToLearn'] as num?)?.toInt(),
    recoveryTime: (json['recoveryTime'] as num?)?.toInt(),
    maxUsages: (json['maxUsages'] as num?)?.toInt(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'useType': useType?.name,
    'energyDamage': energyDamage?.toJson(),
    'minXpToLearn': minXpToLearn,
    'requiredLearnTime': requiredLearnTime,
    'maxUsages': maxUsages,
    'recoveryTime': recoveryTime,
  };

  Spell copyWith({
    String? id,
    String? name,
    String? description,
    UseType? useType,
    EnergyDamage? energyDamage,
    int? requiredLearnTime,
    int? minXpToLearn,
    int? recoveryTime,
    int? maxUsages,
  }) {
    return Spell(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      useType: useType ?? this.useType,
      energyDamage: energyDamage ?? this.energyDamage,
      requiredLearnTime: requiredLearnTime ?? this.requiredLearnTime,
      minXpToLearn: minXpToLearn ?? this.minXpToLearn,
      recoveryTime: recoveryTime ?? this.recoveryTime,
      maxUsages: maxUsages ?? this.maxUsages,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    useType,
    energyDamage,
    requiredLearnTime,
    minXpToLearn,
    recoveryTime,
    maxUsages,
  ];
}
