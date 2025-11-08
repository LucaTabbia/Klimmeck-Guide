import 'package:equatable/equatable.dart';
import 'package:klimmeck_guide/models/base_damage.dart';
import 'package:klimmeck_guide/models/energy_damage.dart';

class Damages extends Equatable {
  const Damages({required this.base, required this.energy});

  final List<BaseDamage>? base;
  final List<EnergyDamage>? energy;

  factory Damages.fromJson(Map<String, dynamic> json) => Damages(
    base: json['base'] != null
        ? List<BaseDamage>.from(json['base'].map((x) => BaseDamage.fromJson(x)))
        : [],
    energy: json['energy'] != null
        ? List<EnergyDamage>.from(
            json['energy'].map((x) => EnergyDamage.fromJson(x)),
          )
        : [],
  );

  Map<String, dynamic> toJson() => {
    'base': base?.map((s) => s.toJson()).toList(),
    'energy': energy?.map((s) => s.toJson()).toList(),
  };

  Damages copyWith({List<BaseDamage>? base, List<EnergyDamage>? energy}) {
    return Damages(base: base ?? this.base, energy: energy ?? this.energy);
  }

  @override
  List<Object?> get props => [base, energy];
}
