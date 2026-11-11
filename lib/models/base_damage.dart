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

  /// Confine di parsing: una voce senza un tipo che il client conosce vale
  /// `null` e viene scartata dalla lista (i lettori indicizzano `type!`).
  static BaseDamage? tryFromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final type = DamageType.values.asNameMap()[json['type']];
    if (type == null) return null;
    final power = json['power'];
    return BaseDamage(type: type, power: power is num ? power.toInt() : null);
  }

  Map<String, dynamic> toJson() => {'type': type?.name, 'power': power};

  BaseDamage copyWith({DamageType? type, int? power}) {
    return BaseDamage(type: type ?? this.type, power: power ?? this.power);
  }

  @override
  List<Object?> get props => [type, power];
}
