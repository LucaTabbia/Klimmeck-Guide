part of 'companion_vitality_cubit.dart';

/// Vita e attesa della pozione di ogni compagno posseduto, per id del
/// compagno a catalogo (D-09, D-05, D-23).
class CompanionVitalityState extends Equatable {
  const CompanionVitalityState({
    this.vitalities = const {},
    this.potionWaits = const {},
    this.sources = const {},
  });

  final Map<String, CompanionVitality> vitalities;

  /// Voce servita da cui è calcolata ogni vita.
  final Map<String, OwnedPet> sources;

  /// Solo i compagni che aspettano ancora la pozione.
  final Map<String, Duration> potionWaits;

  CompanionVitality? vitalityOf(String petId) => vitalities[petId];

  /// Null finché la vita di [owned] non è ricalcolata dalla voce appena
  /// servita: mai la vita di una voce più vecchia (A-03).
  CompanionVitality? vitalityFor(OwnedPet owned) =>
      sources[owned.pet.id] == owned ? vitalities[owned.pet.id] : null;

  Duration? potionWaitOf(String petId) => potionWaits[petId];

  @override
  List<Object?> get props => [vitalities, potionWaits, sources];
}
