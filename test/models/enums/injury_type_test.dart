import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/enums/injury_effect_type.dart';
import 'package:klimmeck_guide/models/enums/injury_type.dart';

/// Nomi di `enum InjuryType` del BE (`src/schema.gql` su `origin/develop`,
/// 2026-10-27, più i nove del quick task 261109-inj2): il test è il registro
/// della parità FE/BE.
const _backendInjuryNames = [
  'blackEye',
  'blindness',
  'brokenLeftArm',
  'brokenLeftLeg',
  'brokenNose',
  'brokenRightArm',
  'brokenRightLeg',
  'contusion',
  'crushedLeftHand',
  'crushedRightHand',
  'deepCut',
  'dislocatedShoulder',
  'exhaustion',
  'fracturedRib',
  'frostbite',
  'headConcussion',
  'hypothermia',
  'infection',
  'internalBleeding',
  'missingLeftArm',
  'missingLeftEye',
  'missingLeftHand',
  'missingLeftLeg',
  'missingRightArm',
  'missingRightEye',
  'missingRightHand',
  'missingRightLeg',
  'muscleTear',
  'paralysis',
  'poisonInjection',
  'punctureWound',
  'puncturedLung',
  'severeBurn',
  'spinalInjury',
  'sprain',
  'stunned',
  'traumaticBrainInjury',
];

const _italianLabels = {
  InjuryType.headConcussion: 'Commozione cerebrale',
  InjuryType.traumaticBrainInjury: 'Trauma cranico',
  InjuryType.missingLeftEye: 'Occhio sinistro mancante',
  InjuryType.missingRightEye: 'Occhio destro mancante',
  InjuryType.blindness: 'Cecità',
  InjuryType.blackEye: 'Occhio nero',
  InjuryType.missingLeftArm: 'Braccio sinistro mancante',
  InjuryType.missingRightArm: 'Braccio destro mancante',
  InjuryType.brokenLeftArm: 'Braccio sinistro rotto',
  InjuryType.brokenRightArm: 'Braccio destro rotto',
  InjuryType.crushedLeftHand: 'Mano sinistra schiacciata',
  InjuryType.crushedRightHand: 'Mano destra schiacciata',
  InjuryType.missingRightHand: 'Mano destra mancante',
  InjuryType.missingLeftHand: 'Mano sinistra mancante',
  InjuryType.brokenRightLeg: 'Gamba destra rotta',
  InjuryType.fracturedRib: 'Costola fratturata',
  InjuryType.puncturedLung: 'Polmone perforato',
  InjuryType.deepCut: 'Taglio profondo',
  InjuryType.severeBurn: 'Ustione grave',
  InjuryType.poisonInjection: 'Iniezione velenosa',
  InjuryType.paralysis: 'Paralisi',
  InjuryType.internalBleeding: 'Emorragia interna',
  InjuryType.frostbite: 'Congelamento',
  InjuryType.infection: 'Infezione',
  InjuryType.spinalInjury: 'Lesione spinale',
  InjuryType.missingLeftLeg: 'Gamba sinistra mancante',
  InjuryType.missingRightLeg: 'Gamba destra mancante',
  InjuryType.brokenLeftLeg: 'Gamba sinistra rotta',
  InjuryType.contusion: 'Contusione',
  InjuryType.punctureWound: 'Ferita da punta',
  InjuryType.muscleTear: 'Strappo muscolare',
  InjuryType.exhaustion: 'Sfinimento',
  InjuryType.sprain: 'Distorsione',
  InjuryType.dislocatedShoulder: 'Spalla lussata',
  InjuryType.brokenNose: 'Naso rotto',
  InjuryType.hypothermia: 'Assideramento',
  InjuryType.stunned: 'Stordimento',
};

/// Le nove ferite del quick task 261109-inj2, nell'ordine della tabella del
/// piano, con severity ed effetti.
const _newInjuries = <InjuryType, (int, List<InjuryEffect>)>{
  InjuryType.contusion: (5, [InjuryEffect.pain]),
  InjuryType.punctureWound: (12, [InjuryEffect.pain, InjuryEffect.bleeding]),
  InjuryType.muscleTear: (15, [InjuryEffect.pain, InjuryEffect.staminaDrain]),
  InjuryType.exhaustion: (10, [InjuryEffect.staminaDrain]),
  InjuryType.sprain: (10, [InjuryEffect.pain, InjuryEffect.movementImpairment]),
  InjuryType.dislocatedShoulder: (
    20,
    [InjuryEffect.pain, InjuryEffect.movementImpairment],
  ),
  InjuryType.brokenNose: (10, [InjuryEffect.pain, InjuryEffect.bleeding]),
  InjuryType.hypothermia: (
    20,
    [InjuryEffect.staminaDrain, InjuryEffect.movementImpairment],
  ),
  InjuryType.stunned: (15, [InjuryEffect.consciousnessLoss]),
};

void main() {
  test('there are 37 injury types', () {
    expect(InjuryType.values.length, 37);
  });

  test('every injury has the Italian label of the research table', () {
    expect(_italianLabels.keys.toSet(), InjuryType.values.toSet());
    for (final MapEntry(key: injury, value: label) in _italianLabels.entries) {
      expect(injury.label, label, reason: injury.name);
    }
  });

  test('the injury names match the backend enum', () {
    expect(
      InjuryType.values.map((injury) => injury.name).toSet(),
      _backendInjuryNames.toSet(),
    );
    expect(_backendInjuryNames, hasLength(37));
  });

  group('quick 261109-inj2', () {
    test('the nine new injuries follow spinalInjury in the table order', () {
      expect(InjuryType.values[27], InjuryType.spinalInjury);
      expect(InjuryType.values.sublist(28), _newInjuries.keys);
    });

    test(
      'the nine new injuries have the severity and effects of the table',
      () {
        for (final MapEntry(key: injury, value: (severity, effects))
            in _newInjuries.entries) {
          expect(injury.severity, severity, reason: injury.name);
          expect(injury.effects, effects, reason: injury.name);
        }
      },
    );

    test('the existing injuries keep their severity and effects', () {
      expect(InjuryType.blackEye.severity, 5);
      expect(InjuryType.blackEye.effects, [InjuryEffect.visionLoss]);
      expect(InjuryType.spinalInjury.severity, 80);
      expect(InjuryType.spinalInjury.effects, [
        InjuryEffect.pain,
        InjuryEffect.staminaDrain,
        InjuryEffect.movementImpairment,
      ]);
    });
  });

  group('injuryTypesFrom', () {
    test('reads the known names in wire order (D-01)', () {
      expect(injuryTypesFrom(['deepCut', 'contusion']), [
        InjuryType.deepCut,
        InjuryType.contusion,
      ]);
    });

    test('drops unknown names and non-strings (D-01)', () {
      expect(injuryTypesFrom(['contusion', 'dragonBite', 42, null]), [
        InjuryType.contusion,
      ]);
    });

    test('anything but a list is an empty list (D-01)', () {
      expect(injuryTypesFrom(null), isEmpty);
      expect(injuryTypesFrom('contusion'), isEmpty);
      expect(injuryTypesFrom(<String, dynamic>{}), isEmpty);
    });

    test('the list cannot be modified (D-01)', () {
      final injuries = injuryTypesFrom(['contusion']);
      expect(() => injuries.add(InjuryType.deepCut), throwsUnsupportedError);
    });
  });
}
