import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/utils/game_duration_format.dart';

void main() {
  group('formatGameDuration', () {
    final cases = <Duration, String>{
      const Duration(seconds: 30): '1 min',
      const Duration(minutes: 40): '40 min',
      const Duration(minutes: 40, seconds: 1): '41 min',
      const Duration(hours: 1): '1 h',
      const Duration(hours: 2, minutes: 40): '2 h 40 min',
      const Duration(hours: 23, minutes: 59, seconds: 30): '1 g',
      const Duration(hours: 24): '1 g',
      const Duration(hours: 27, minutes: 10): '1 g 3 h',
      const Duration(hours: 48): '2 g',
      const Duration(hours: 82, minutes: 18): '3 g 10 h',
      Duration.zero: '0 min',
      const Duration(minutes: -5): '0 min',
    };

    cases.forEach((duration, expected) {
      test('$duration reads "$expected"', () {
        expect(formatGameDuration(duration), expected);
      });
    });
  });
}
