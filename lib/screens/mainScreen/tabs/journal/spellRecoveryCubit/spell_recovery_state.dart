part of 'spell_recovery_cubit.dart';

/// Stato di recupero di ogni magia conosciuta, per id (D-04, D-05).
class SpellRecoveryState extends Equatable {
  const SpellRecoveryState(this.statuses);

  final Map<String, SpellRecoveryStatus> statuses;

  SpellRecoveryStatus statusOf(String spellId) =>
      statuses[spellId] ?? const SpellRecoveryFull();

  @override
  List<Object?> get props => [statuses];
}
