import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/enums/city_type.dart';

void main() {
  test('only Talmvere keeps its marker visible at every zoom (D-13)', () {
    expect(CityType.values.where((type) => type.alwaysVisible), [
      CityType.talmvereVillage,
    ]);
  });
}
