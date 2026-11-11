import 'package:equatable/equatable.dart';
import 'package:klimmeck_guide/models/enums/damage_type.dart';
import 'package:klimmeck_guide/models/enums/energy_type.dart';

class Weaknesses extends Equatable {
  const Weaknesses({this.base = const [], this.energy = const []});

  /// Mai un'eccezione: ciò che non è una mappa vale il valore vuoto, ciò che
  /// non è una lista una lista vuota, un nome sconosciuto è scartato.
  factory Weaknesses.fromJson(Object? json) {
    if (json is! Map<String, dynamic>) return const Weaknesses();
    return Weaknesses(
      base: _namesFrom(json['base'], DamageType.values.asNameMap()),
      energy: _namesFrom(json['energy'], EnergyType.values.asNameMap()),
    );
  }

  static List<T> _namesFrom<T>(Object? json, Map<String, T> byName) =>
      json is List
      ? List<T>.unmodifiable(json.map((name) => byName[name]).nonNulls)
      : const [];

  final List<DamageType> base;
  final List<EnergyType> energy;

  Map<String, dynamic> toJson() => {
    'base': [for (final type in base) type.name],
    'energy': [for (final type in energy) type.name],
  };

  @override
  List<Object?> get props => [base, energy];
}
