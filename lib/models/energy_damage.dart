import 'enums/energy_type.dart';

class EnergyDamage {
  EnergyDamage({required this.type, required this.power});

  final EnergyType? type;
  final int? power;

  factory EnergyDamage.fromJson(Map<String, dynamic> json) => EnergyDamage(
    type: json['type'] != null ? EnergyType.values.byName(json['type']) : null,
    power: json['power'] != null ? (json['power'] as num).toInt() : null,
  );

  Map<String, dynamic> toJson() => {'type': type?.name, 'power': power};
}
