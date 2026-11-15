import 'dart:math' as math;

import 'package:equatable/equatable.dart';
import 'package:klimmeck_guide/models/owned_pet.dart';

/// Cosa la pergamena del compagno mostra della sua vita in un istante (D-09).
/// Letta solo dalle date servite: il FE non decide mai una sconfitta né una
/// pendenza (CLAUDE.md regola 4).
sealed class CompanionVitality extends Equatable {
  const CompanionVitality({required this.life, required this.maxLifePoints});

  final int life;
  final int? maxLifePoints;

  @override
  List<Object?> get props => [life, maxLifePoints];
}

/// Vita ferma: equipaggiato (D-04), senza date o già in forze (D-24).
final class CompanionSteady extends CompanionVitality {
  const CompanionSteady({required super.life, required super.maxLifePoints});
}

/// A riposo: la vita sale fino a `fullLifeAt`, fra [remaining].
final class CompanionResting extends CompanionVitality {
  const CompanionResting({
    required super.life,
    required super.maxLifePoints,
    required this.remaining,
  });

  final Duration remaining;

  @override
  List<Object?> get props => [...super.props, remaining];
}

/// Sconfitto: non equipaggiabile finché non torna in forze fra [remaining]
/// (D-02).
final class CompanionDefeated extends CompanionVitality {
  const CompanionDefeated({
    required super.life,
    required super.maxLifePoints,
    required this.remaining,
  });

  final Duration remaining;

  @override
  List<Object?> get props => [...super.props, remaining];
}

/// Interpolazione lineare fra (`currentLifePoints` a `lifeAsOf`) e la vita
/// massima del compagno a `fullLifeAt` (D-38), arrotondata al punto più
/// vicino come il BE (D-24) e ferma a `max − 1` prima di `fullLifeAt`
/// (Pitfall 8).
CompanionVitality companionVitalityOf(
  OwnedPet owned,
  DateTime now, {
  required bool isEquipped,
}) {
  final max = owned.effectiveMaxLifePoints;
  final lifeAsOf = owned.lifeAsOf;
  final fullLifeAt = owned.fullLifeAt;
  if (max == null || isEquipped || lifeAsOf == null || fullLifeAt == null) {
    return CompanionSteady(life: owned.currentLifePoints, maxLifePoints: max);
  }
  if (!now.isBefore(fullLifeAt)) {
    return CompanionSteady(life: max, maxLifePoints: max);
  }
  final life = _interpolatedLife(
    from: owned.currentLifePoints,
    to: max,
    spanMs: fullLifeAt.difference(lifeAsOf).inMilliseconds,
    elapsedMs: now.difference(lifeAsOf).inMilliseconds,
  );
  final remaining = fullLifeAt.difference(now);
  if (owned.isDefeated) {
    return CompanionDefeated(
      life: life,
      maxLifePoints: max,
      remaining: remaining,
    );
  }
  return CompanionResting(life: life, maxLifePoints: max, remaining: remaining);
}

/// Sconfitto per la pergamena: la vita calcolata, o la voce servita finché
/// la vita non è ricalcolata (D-02).
bool isCompanionDefeated(OwnedPet owned, CompanionVitality? vitality) =>
    vitality == null ? owned.isDefeated : vitality is CompanionDefeated;

/// Attesa della pozione del compagno: fino alla sua data servita, null quando
/// passata o assente (D-05).
Duration? companionPotionWaitOf(OwnedPet owned, DateTime now) {
  final until = owned.potionRecoveryUntil;
  if (until == null || !now.isBefore(until)) return null;
  return until.difference(now);
}

/// Solo interi, come `Math.round` del BE: mezzo punto arrotonda in su,
/// senza l'errore di una frazione in virgola mobile.
int _interpolatedLife({
  required int from,
  required int to,
  required int spanMs,
  required int elapsedMs,
}) {
  if (spanMs <= 0) return math.max(from, to - 1);
  final elapsed = elapsedMs.clamp(0, spanMs);
  final risen = from + ((to - from) * elapsed * 2 + spanMs) ~/ (2 * spanMs);
  return math.max(from, math.min(risen, to - 1));
}
