import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/enums/race_type.dart';

void main() {
  test(
    'the winged people and the void-born are named Volucre and Infernale',
    () {
      expect(RaceType.volucri.label, 'Volucre');
      expect(RaceType.infernal.label, 'Infernale');
    },
  );
}
