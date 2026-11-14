import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/enums/poi_type.dart';

void main() {
  test('every PoiType has a non-empty Italian label (D-29)', () {
    for (final type in PoiType.values) {
      expect(type.label, isNotEmpty, reason: type.name);
    }
  });

  test('ruins is «Rovine», forest «Foresta», demonicPortal «Portale demoniaco» '
      '(D-29)', () {
    expect(PoiType.ruins.label, 'Rovine');
    expect(PoiType.forest.label, 'Foresta');
    expect(PoiType.demonicPortal.label, 'Portale demoniaco');
  });

  test('a served demonicPortal is no longer dropped (D-29)', () {
    expect(poiTypesFrom(['vulcano', 'demonicPortal']), [
      PoiType.vulcano,
      PoiType.demonicPortal,
    ]);
  });

  test('an unknown name is still dropped', () {
    expect(poiTypesFrom(['moon']), isEmpty);
  });
}
