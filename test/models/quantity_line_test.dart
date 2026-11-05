import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/quantity_line.dart';

void main() {
  test('writes «Nx nome» with the quantity before the name (D-11)', () {
    expect(quantityLine(3, 'Goblin'), '3x Goblin');
  });

  test('keeps a quantity of one explicit (D-11)', () {
    expect(quantityLine(1, 'Razione da viaggio'), '1x Razione da viaggio');
  });
}
