import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/shared/components/tear/tear_gesture.dart';

void main() {
  const gesture = TearGesture();

  group('progress', () {
    test('maps a left drag to a fraction of the travel', () {
      expect(gesture.progress(-90, 400), closeTo(0.5, 1e-9));
    });

    test('clamps at 1', () {
      expect(gesture.progress(-500, 400), 1.0);
    });

    test('ignores a right drag', () {
      expect(gesture.progress(120, 400), 0.0);
    });

    test('is 0 for a zero width', () {
      expect(gesture.progress(-50, 0), 0.0);
    });
  });

  group('shouldTear', () {
    test('tears at full progress', () {
      expect(gesture.shouldTear(1.0, 0), isTrue);
    });

    test('tears on a fast fling past the fling progress', () {
      expect(gesture.shouldTear(0.5, -1000), isTrue);
    });

    test('does not tear a fling below the fling progress', () {
      expect(gesture.shouldTear(0.3, -2000), isFalse);
    });

    test('does not tear a slow drag', () {
      expect(gesture.shouldTear(0.6, -500), isFalse);
    });
  });

  group('resisted', () {
    test('caps the progress', () {
      expect(gesture.resisted(0.8), 0.12);
    });

    test('keeps small progress', () {
      expect(gesture.resisted(0.05), 0.05);
    });
  });

  group('ThresholdLatch', () {
    test('fires once per drag', () {
      final latch = ThresholdLatch();
      expect(latch.cross(false), isFalse);
      expect(latch.cross(true), isTrue);
      expect(latch.cross(true), isFalse);
      latch.reset();
      expect(latch.cross(true), isTrue);
    });
  });
}
