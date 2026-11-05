import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/enums/accessory_use_type.dart';

void main() {
  test('labels read Attacco and Difesa (D-15)', () {
    expect(AccessoryUseType.attack.label, 'Attacco');
    expect(AccessoryUseType.defense.label, 'Difesa');
  });

  test('wire names are attack and defense (D-15)', () {
    expect(AccessoryUseType.values.map((type) => type.name), [
      'attack',
      'defense',
    ]);
  });
}
