import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/config/companion_care.dart';

void main() {
  test('the companion care switch is on after the gate (Pitfall 3)', () {
    expect(companionCareEnabled, isTrue);
  });
}
