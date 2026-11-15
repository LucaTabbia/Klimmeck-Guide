import 'package:equatable/equatable.dart';
import 'package:klimmeck_guide/models/energy_damage.dart';

import 'enums/spell_origin.dart';
import 'enums/use_type.dart';

class Spell extends Equatable {
  const Spell({
    required this.id,
    required this.name,
    required this.description,
    required this.origin,
    required this.useType,
    required this.energyDamage,
    required this.requiredLearnTime,
    required this.minLevelToLearn,
    required this.recoveryTime,
    required this.maxUsages,
  });

  final String id;
  final String? name;
  final String? description;

  /// Origine servita dal backend (D-01); null = ignota a questo client: la
  /// magia resta e l'origine non si disegna.
  final SpellOrigin? origin;

  final UseType? useType;
  final EnergyDamage? energyDamage;
  final int? requiredLearnTime;

  /// Livello minimo per impararla, servito dal backend (D-07): il FE lo stampa
  /// soltanto, non lo confronta mai (D-08).
  final int? minLevelToLearn;

  final int? recoveryTime;
  final int? maxUsages;

  factory Spell.fromJson(Map<String, dynamic> json) => Spell(
    id: json['id'],
    name: json['name'],
    description: json['description'],
    origin: SpellOrigin.fromWire(json['origin']),
    useType: UseType.values.asNameMap()[json['useType']],
    energyDamage: EnergyDamage.tryFromJson(json['energyDamage']),
    requiredLearnTime: (json['requiredLearnTime'] as num?)?.toInt(),
    minLevelToLearn: _levelOf(json['minLevelToLearn']),
    recoveryTime: (json['recoveryTime'] as num?)?.toInt(),
    maxUsages: (json['maxUsages'] as num?)?.toInt(),
  );

  static int? _levelOf(Object? value) => value is num ? value.toInt() : null;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'origin': origin?.wireName,
    'useType': useType?.name,
    'energyDamage': energyDamage?.toJson(),
    'minLevelToLearn': minLevelToLearn,
    'requiredLearnTime': requiredLearnTime,
    'maxUsages': maxUsages,
    'recoveryTime': recoveryTime,
  };

  Spell copyWith({
    String? id,
    String? name,
    String? description,
    SpellOrigin? origin,
    UseType? useType,
    EnergyDamage? energyDamage,
    int? requiredLearnTime,
    int? minLevelToLearn,
    int? recoveryTime,
    int? maxUsages,
  }) {
    return Spell(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      origin: origin ?? this.origin,
      useType: useType ?? this.useType,
      energyDamage: energyDamage ?? this.energyDamage,
      requiredLearnTime: requiredLearnTime ?? this.requiredLearnTime,
      minLevelToLearn: minLevelToLearn ?? this.minLevelToLearn,
      recoveryTime: recoveryTime ?? this.recoveryTime,
      maxUsages: maxUsages ?? this.maxUsages,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    origin,
    useType,
    energyDamage,
    requiredLearnTime,
    minLevelToLearn,
    recoveryTime,
    maxUsages,
  ];
}
