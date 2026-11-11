import 'package:equatable/equatable.dart';
import 'package:klimmeck_guide/models/base_damage.dart';
import 'package:klimmeck_guide/models/energy_damage.dart';

class Damages extends Equatable {
  const Damages({required this.base, required this.energy});

  final List<BaseDamage>? base;
  final List<EnergyDamage>? energy;

  factory Damages.fromJson(Map<String, dynamic> json) => Damages(
    base: _entriesFrom(json['base'], BaseDamage.tryFromJson),
    energy: _entriesFrom(json['energy'], EnergyDamage.tryFromJson),
  );

  static List<T> _entriesFrom<T extends Object>(
    Object? json,
    T? Function(Object?) tryParse,
  ) => json is List ? List<T>.from(json.map(tryParse).nonNulls) : <T>[];

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
