import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/enums/sex_type.dart';

void main() {
  test('label is the Italian display name', () {
    expect(SexType.male.label, 'Maschio');
    expect(SexType.female.label, 'Femmina');
  });
}
