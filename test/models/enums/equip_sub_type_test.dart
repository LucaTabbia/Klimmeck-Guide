import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/enums/equip_sub_type.dart';

void main() {
  test('mirrors the weapon families served by the backend', () {
    expect(EquipSubType.values.map((type) => type.name), [
      'sword',
      'greatsword',
      'dagger',
      'axe',
      'mace',
      'warHammer',
      'spear',
      'bow',
      'shortStaff',
      'longStaff',
      'wand',
      'grimoire',
    ]);
  });

  test('marks the two-handed families like the backend', () {
    expect(EquipSubType.values.where((type) => type.isTwoHanded), [
      EquipSubType.greatsword,
      EquipSubType.warHammer,
      EquipSubType.spear,
      EquipSubType.bow,
      EquipSubType.longStaff,
    ]);
  });

  test('names every family in Italian', () {
    expect(EquipSubType.greatsword.label, 'Spadone');
    expect(EquipSubType.grimoire.label, 'Grimorio');
    expect(EquipSubType.warHammer.label, 'Martello da guerra');
  });
}
