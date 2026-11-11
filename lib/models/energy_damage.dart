import 'package:equatable/equatable.dart';

import 'enums/energy_type.dart';

class EnergyDamage extends Equatable {
  const EnergyDamage({required this.type, required this.power});

  final EnergyType? type;
  final int? power;

  factory EnergyDamage.fromJson(Map<String, dynamic> json) => EnergyDamage(
    type: json['type'] != null ? EnergyType.values.byName(json['type']) : null,
    power: json['power'] != null ? (json['power'] as num).toInt() : null,
  );

  /// Confine di parsing: una voce senza un tipo che il client conosce vale
  /// `null` e viene scartata dalla lista (i lettori indicizzano `type!`).
  static EnergyDamage? tryFromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final type = EnergyType.values.asNameMap()[json['type']];
    if (type == null) return null;
    final power = json['power'];
    return EnergyDamage(type: type, power: power is num ? power.toInt() : null);
  }

  Map<String, dynamic> toJson() => {'type': type?.name, 'power': power};

  EnergyDamage copyWith({EnergyType? type, int? power}) {
    return EnergyDamage(type: type ?? this.type, power: power ?? this.power);
  }

  @override
  List<Object?> get props => [type, power];
}
