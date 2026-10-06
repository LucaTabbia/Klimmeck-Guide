import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/utils/backoff.dart';

void main() {
  group('exponentialBackoff', () {
    test('doubles from 1 s', () {
      expect(exponentialBackoff(0), const Duration(seconds: 1));
      expect(exponentialBackoff(1), const Duration(seconds: 2));
      expect(exponentialBackoff(2), const Duration(seconds: 4));
      expect(exponentialBackoff(4), const Duration(seconds: 16));
    });

    test('is capped at 30 s by default', () {
      expect(exponentialBackoff(5), const Duration(seconds: 30));
    });

    test('does not overflow for large attempts', () {
      expect(exponentialBackoff(40), const Duration(seconds: 30));
    });

    test('treats a negative attempt as the first one', () {
      expect(exponentialBackoff(-3), const Duration(seconds: 1));
    });

    test('honours a custom cap', () {
      const max = Duration(seconds: 60);
      expect(exponentialBackoff(5, max: max), const Duration(seconds: 32));
      expect(exponentialBackoff(6, max: max), const Duration(seconds: 60));
    });
  });
}
