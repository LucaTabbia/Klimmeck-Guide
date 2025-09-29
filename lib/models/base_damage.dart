import 'package:klimmeck_guide/models/enums/damage_type.dart';

class BaseDamage {
  BaseDamage({required this.type, required this.power});

  final DamageType? type;
  final int? power;

  factory BaseDamage.fromJson(Map<String, dynamic> json) => BaseDamage(
    type: json['type'] != null ? DamageType.values.byName(json['type']) : null,
    power: json['power'] != null ? (json['power'] as num).toInt() : null,
  );

  Map<String, dynamic> toJson() => {'type': type?.name, 'power': power};
}
