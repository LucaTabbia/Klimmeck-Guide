import 'package:equatable/equatable.dart';
import 'package:klimmeck_guide/models/enums/damage_type.dart';

class BaseDamage extends Equatable {
  const BaseDamage({required this.type, required this.power});

  final DamageType? type;
  final int? power;

  factory BaseDamage.fromJson(Map<String, dynamic> json) => BaseDamage(
    type: json['type'] != null ? DamageType.values.byName(json['type']) : null,
    power: json['power'] != null ? (json['power'] as num).toInt() : null,
  );

  Map<String, dynamic> toJson() => {'type': type?.name, 'power': power};

  BaseDamage copyWith({DamageType? type, int? power}) {
    return BaseDamage(type: type ?? this.type, power: power ?? this.power);
  }

  @override
  List<Object?> get props => [type, power];
}
