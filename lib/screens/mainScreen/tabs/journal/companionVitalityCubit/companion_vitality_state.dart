part of 'companion_vitality_cubit.dart';

/// Vita e attesa della pozione di ogni compagno posseduto, per id del
/// compagno a catalogo (D-09, D-05, D-23).
class CompanionVitalityState extends Equatable {
  const CompanionVitalityState({
    this.vitalities = const {},
    this.potionWaits = const {},
  });

  final Map<String, CompanionVitality> vitalities;

  /// Solo i compagni che aspettano ancora la pozione.
  final Map<String, Duration> potionWaits;

  CompanionVitality? vitalityOf(String petId) => vitalities[petId];

  Duration? potionWaitOf(String petId) => potionWaits[petId];

  @override
  List<Object?> get props => [vitalities, potionWaits];
}
