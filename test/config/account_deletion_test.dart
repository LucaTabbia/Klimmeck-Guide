import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/config/account_deletion.dart';

void main() {
  test('the switch is off before the gate (25-07 flips it)', () {
    expect(accountDeletionEnabled, isFalse);
  });
}
