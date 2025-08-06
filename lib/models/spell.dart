import 'package:klimmeck_guide/models/enums/use_type.dart';

import 'enums/energy_type.dart';

class Spell {
  Spell({
    required this.id,
    required this.name,
    required this.useType,
    required this.energyType,
    required this.power,
    required this.requiredLearnTime,
    required this.minXpToLearn,
  });

  final String id;
  final String name;
  final UseType useType;
  final EnergyType energyType;
  final int power;
  final int requiredLearnTime;
  final int minXpToLearn;

  factory Spell.fromJson(Map<String, dynamic> json) => Spell(
    id: json['id'],
    name: json['name'],
    useType: UseType.values.byName(json['useType']),
    energyType: EnergyType.values.byName(json['energyType']),
    power: (json['power'] as num).toInt(),
    requiredLearnTime: (json['requiredLearnTime'] as num).toInt(),
    minXpToLearn: (json['minXpToLearn'] as num).toInt(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'useType': useType.name,
    'energyType': energyType.name,
    'power': power,
    'minXpToLearn': minXpToLearn,
    'requiredLearnTime': requiredLearnTime,
  };
}
