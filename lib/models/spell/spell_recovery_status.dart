import 'package:equatable/equatable.dart';

/// Dati di recupero di una magia conosciuta (D-02): usi, massimo e istanti UTC.
class SpellRecoveryInput extends Equatable {
  const SpellRecoveryInput({
    required this.spellId,
    required this.usages,
    required this.maxUsages,
    required this.recoveries,
  });

  final String spellId;
  final int usages;
  final int? maxUsages;
  final List<DateTime> recoveries;

  @override
  List<Object?> get props => [spellId, usages, maxUsages, recoveries];
}

/// Cosa la riga mostra del recupero (D-04). Quantizzato su ciò che l'etichetta
/// dice, così due istanti con la stessa etichetta sono lo stesso stato.
sealed class SpellRecoveryStatus extends Equatable {
  const SpellRecoveryStatus();

  @override
  List<Object?> get props => [];
}

/// Usi al massimo: nessuna riga di recupero.
final class SpellRecoveryFull extends SpellRecoveryStatus {
  const SpellRecoveryFull();
}

/// Prossimo uso tra [remainingMinutes] minuti arrotondati per eccesso;
/// 0 = meno di un minuto.
final class SpellRecoveryCountdown extends SpellRecoveryStatus {
  const SpellRecoveryCountdown({required this.remainingMinutes});

  final int remainingMinutes;

  @override
  List<Object?> get props => [remainingMinutes];
}

/// Istante passato, `characterUpdated` non ancora arrivato (sweep BE ≤ 60 s).
final class SpellRecoveryArriving extends SpellRecoveryStatus {
  const SpellRecoveryArriving();
}

/// Sotto il massimo senza istanti (job legacy pre-9.1 o backend pre-9.1,
/// D-03/D-04).
final class SpellRecoveryUnknown extends SpellRecoveryStatus {
  const SpellRecoveryUnknown();
}

/// Unico calcolo ammesso lato client: `recoveries[0] − serverNow` (D-04,
/// CLAUDE.md regola 4). Gli usi non vengono mai incrementati qui.
SpellRecoveryStatus spellRecoveryStatusOf(
  SpellRecoveryInput input,
  DateTime serverNow,
) {
  final maxUsages = input.maxUsages;
  if (maxUsages == null || input.usages >= maxUsages) {
    return const SpellRecoveryFull();
  }
  if (input.recoveries.isEmpty) return const SpellRecoveryUnknown();
  final next = input.recoveries.reduce((a, b) => a.isBefore(b) ? a : b);
  final remaining = next.difference(serverNow);
  if (remaining <= Duration.zero) return const SpellRecoveryArriving();
  return SpellRecoveryCountdown(
    remainingMinutes: _wholeMinutesShown(remaining),
  );
}

int _wholeMinutesShown(Duration remaining) {
  if (remaining < const Duration(minutes: 1)) return 0;
  return (remaining.inMilliseconds / Duration.millisecondsPerMinute).ceil();
}
