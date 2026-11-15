import 'package:equatable/equatable.dart';
import 'package:klimmeck_guide/models/companion/companion_display_name.dart';
import 'package:klimmeck_guide/models/companion/companion_vitality.dart';
import 'package:klimmeck_guide/models/owned_pet.dart';

/// Un compagno a cui il foglio della pozione può darla (D-07, D-08): la vita
/// è quella della sua pergamena in quell'istante, sul suo massimo (D-38).
class CompanionPotionTarget extends Equatable {
  const CompanionPotionTarget({
    required this.owned,
    required this.life,
    required this.maxLifePoints,
  });

  final OwnedPet owned;
  final int life;
  final int maxLifePoints;

  String get petId => owned.pet.id;

  String get name => companionDisplayNameOf(owned);

  @override
  List<Object?> get props => [owned, life, maxLifePoints];
}

/// I compagni che potrebbero bere adesso, nell'ordine servito: non sconfitti
/// (D-06), sotto il proprio massimo, equipaggiati o a riposo (D-07), senza
/// un'attesa propria (D-32). Solo visualizzazione: il giudice resta il BE.
List<CompanionPotionTarget> companionPotionTargetsOf(
  List<OwnedPet> owned, {
  required CompanionVitality? Function(String petId) vitalityOf,
  required Duration? Function(String petId) potionWaitOf,
}) => [
  for (final companion in owned)
    if (_targetOf(companion, vitalityOf(companion.pet.id), potionWaitOf)
        case final target?)
      target,
];

CompanionPotionTarget? _targetOf(
  OwnedPet owned,
  CompanionVitality? vitality,
  Duration? Function(String petId) potionWaitOf,
) {
  if (vitality == null || vitality is CompanionDefeated) return null;
  final max = vitality.maxLifePoints;
  if (max == null || vitality.life >= max) return null;
  if (potionWaitOf(owned.pet.id) != null) return null;
  return CompanionPotionTarget(
    owned: owned,
    life: vitality.life,
    maxLifePoints: max,
  );
}
