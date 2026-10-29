import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/enums/injury_type.dart';

/// Nomi di `enum InjuryType` del BE (`src/schema.gql` su `origin/develop`,
/// 2026-10-27): il test è il registro della parità FE/BE.
const _backendInjuryNames = [
  'blackEye',
  'blindness',
  'brokenLeftArm',
  'brokenLeftLeg',
  'brokenRightArm',
  'brokenRightLeg',
  'crushedLeftHand',
  'crushedRightHand',
  'deepCut',
  'fracturedRib',
  'frostbite',
  'headConcussion',
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
  'paralysis',
  'poisonInjection',
  'puncturedLung',
  'severeBurn',
  'spinalInjury',
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
};

void main() {
  test('there are 28 injury types', () {
    expect(InjuryType.values.length, 28);
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
    expect(_backendInjuryNames, hasLength(28));
  });
}
