import 'injury_effect_type.dart';

enum InjuryType {
  headConcussion(severity: 40, effects: [InjuryEffect.consciousnessLoss]),
  traumaticBrainInjury(
    severity: 50,
    effects: [InjuryEffect.pain, InjuryEffect.consciousnessLoss],
  ),
  missingLeftEye(severity: 30, effects: [InjuryEffect.visionLoss]),
  missingRightEye(severity: 30, effects: [InjuryEffect.visionLoss]),
  blindness(severity: 50, effects: [InjuryEffect.visionLoss]),
  blackEye(severity: 5, effects: [InjuryEffect.visionLoss]),
  missingLeftArm(severity: 50, effects: [InjuryEffect.movementImpairment]),
  missingRightArm(severity: 50, effects: [InjuryEffect.movementImpairment]),
  brokenLeftArm(
    severity: 20,
    effects: [InjuryEffect.pain, InjuryEffect.movementImpairment],
  ),
  brokenRightArm(
    severity: 20,
    effects: [InjuryEffect.pain, InjuryEffect.movementImpairment],
  ),
  crushedLeftHand(
    severity: 20,
    effects: [InjuryEffect.pain, InjuryEffect.movementImpairment],
  ),
  crushedRightHand(
    severity: 20,
    effects: [InjuryEffect.pain, InjuryEffect.movementImpairment],
  ),
  missingRightHand(severity: 40, effects: [InjuryEffect.movementImpairment]),
  missingLeftHand(severity: 40, effects: [InjuryEffect.movementImpairment]),
  missingLeftLeg(severity: 60, effects: [InjuryEffect.movementImpairment]),
  missingRightLeg(severity: 60, effects: [InjuryEffect.movementImpairment]),
  brokenLeftLeg(
    severity: 20,
    effects: [InjuryEffect.pain, InjuryEffect.movementImpairment],
  ),
  brokenRightLeg(
    severity: 20,
    effects: [InjuryEffect.pain, InjuryEffect.movementImpairment],
  ),
  fracturedRib(
    severity: 60,
    effects: [InjuryEffect.pain, InjuryEffect.movementImpairment],
  ),
  puncturedLung(
    severity: 40,
    effects: [InjuryEffect.pain, InjuryEffect.staminaDrain],
  ),
  deepCut(severity: 10, effects: [InjuryEffect.pain, InjuryEffect.bleeding]),
  severeBurn(severity: 15, effects: [InjuryEffect.pain]),
  poisonInjection(
    severity: 30,
    effects: [InjuryEffect.pain, InjuryEffect.poisoned],
  ),
  paralysis(
    severity: 70,
    effects: [
      InjuryEffect.pain,
      InjuryEffect.paralysis,
      InjuryEffect.movementImpairment,
    ],
  ),
  internalBleeding(
    severity: 40,
    effects: [InjuryEffect.pain, InjuryEffect.bleeding],
  ),
  frostbite(
    severity: 20,
    effects: [InjuryEffect.pain, InjuryEffect.staminaDrain],
  ),
  infection(severity: 25, effects: [InjuryEffect.pain, InjuryEffect.infection]),
  spinalInjury(
    severity: 80,
    effects: [
      InjuryEffect.pain,
      InjuryEffect.staminaDrain,
      InjuryEffect.movementImpairment,
    ],
  ),
  contusion(severity: 5, effects: [InjuryEffect.pain]),
  punctureWound(
    severity: 12,
    effects: [InjuryEffect.pain, InjuryEffect.bleeding],
  ),
  muscleTear(
    severity: 15,
    effects: [InjuryEffect.pain, InjuryEffect.staminaDrain],
  ),
  exhaustion(severity: 10, effects: [InjuryEffect.staminaDrain]),
  sprain(
    severity: 10,
    effects: [InjuryEffect.pain, InjuryEffect.movementImpairment],
  ),
  dislocatedShoulder(
    severity: 20,
    effects: [InjuryEffect.pain, InjuryEffect.movementImpairment],
  ),
  brokenNose(severity: 10, effects: [InjuryEffect.pain, InjuryEffect.bleeding]),
  hypothermia(
    severity: 20,
    effects: [InjuryEffect.staminaDrain, InjuryEffect.movementImpairment],
  ),
  stunned(severity: 15, effects: [InjuryEffect.consciousnessLoss]);

  final int severity;
  final List<InjuryEffect> effects;
  bool hasEffect(InjuryEffect effect) => effects.contains(effect);

  const InjuryType({required this.severity, required this.effects});
}

extension InjuryTypeExtension on InjuryType {
  String get label {
    switch (this) {
      case InjuryType.headConcussion:
        return 'Commozione cerebrale';
      case InjuryType.traumaticBrainInjury:
        return 'Trauma cranico';
      case InjuryType.missingLeftEye:
        return 'Occhio sinistro mancante';
      case InjuryType.missingRightEye:
        return 'Occhio destro mancante';
      case InjuryType.blindness:
        return 'Cecità';
      case InjuryType.blackEye:
        return 'Occhio nero';
      case InjuryType.missingLeftArm:
        return 'Braccio sinistro mancante';
      case InjuryType.missingRightArm:
        return 'Braccio destro mancante';
      case InjuryType.brokenLeftArm:
        return 'Braccio sinistro rotto';
      case InjuryType.brokenRightArm:
        return 'Braccio destro rotto';
      case InjuryType.crushedLeftHand:
        return 'Mano sinistra schiacciata';
      case InjuryType.crushedRightHand:
        return 'Mano destra schiacciata';
      case InjuryType.missingRightHand:
        return 'Mano destra mancante';
      case InjuryType.missingLeftHand:
        return 'Mano sinistra mancante';
      case InjuryType.missingLeftLeg:
        return 'Gamba sinistra mancante';
      case InjuryType.missingRightLeg:
        return 'Gamba destra mancante';
      case InjuryType.brokenLeftLeg:
        return 'Gamba sinistra rotta';
      case InjuryType.brokenRightLeg:
        return 'Gamba destra rotta';
      case InjuryType.fracturedRib:
        return 'Costola fratturata';
      case InjuryType.puncturedLung:
        return 'Polmone perforato';
      case InjuryType.deepCut:
        return 'Taglio profondo';
      case InjuryType.severeBurn:
        return 'Ustione grave';
      case InjuryType.poisonInjection:
        return 'Iniezione velenosa';
      case InjuryType.paralysis:
        return 'Paralisi';
      case InjuryType.internalBleeding:
        return 'Emorragia interna';
      case InjuryType.frostbite:
        return 'Congelamento';
      case InjuryType.infection:
        return 'Infezione';
      case InjuryType.spinalInjury:
        return 'Lesione spinale';
      case InjuryType.contusion:
        return 'Contusione';
      case InjuryType.punctureWound:
        return 'Ferita da punta';
      case InjuryType.muscleTear:
        return 'Strappo muscolare';
      case InjuryType.exhaustion:
        return 'Sfinimento';
      case InjuryType.sprain:
        return 'Distorsione';
      case InjuryType.dislocatedShoulder:
        return 'Spalla lussata';
      case InjuryType.brokenNose:
        return 'Naso rotto';
      case InjuryType.hypothermia:
        return 'Assideramento';
      case InjuryType.stunned:
        return 'Stordimento';
    }
  }
}
