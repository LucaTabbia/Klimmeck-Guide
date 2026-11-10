part of 'potion_recovery_cubit.dart';

/// Tempo che manca alla fine della ricarica delle pozioni, arrotondato per
/// eccesso al minuto (come lo mostra l'etichetta); `null` = pronta.
class PotionRecoveryState extends Equatable {
  const PotionRecoveryState(this.remaining);

  final Duration? remaining;

  bool get isRecovering => remaining != null;

  @override
  List<Object?> get props => [remaining];
}
