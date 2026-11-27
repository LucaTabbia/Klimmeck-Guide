import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/shop/utils/pouch_flight.dart';

void main() {
  const flight = PouchFlight(start: Offset(400, 300), target: Offset(100, 300));

  group('progressAt', () {
    test('is zero where the pouch rests', () {
      expect(flight.progressAt(const Offset(400, 300)), 0);
    });

    test('grows as the pouch nears the shopkeeper', () {
      expect(flight.progressAt(const Offset(250, 300)), closeTo(0.5, 1e-9));
    });

    test('is one on the shopkeeper', () {
      expect(flight.progressAt(const Offset(100, 300)), 1);
    });

    test('never goes below zero when the pouch moves away', () {
      expect(flight.progressAt(const Offset(800, 300)), 0);
    });
  });

  group('scaleAt', () {
    test('keeps the full size where the pouch rests', () {
      expect(flight.scaleAt(const Offset(400, 300)), 1);
    });

    test('shrinks steadily on the way', () {
      final halfway = flight.scaleAt(const Offset(250, 300));
      final close = flight.scaleAt(const Offset(150, 300));

      expect(halfway, lessThan(1));
      expect(close, lessThan(halfway));
    });

    test('reaches the smallest size on the shopkeeper', () {
      expect(
        flight.scaleAt(const Offset(100, 300)),
        closeTo(PouchFlight.smallestScale, 1e-9),
      );
    });
  });

  group('reachesShopkeeper', () {
    test('a pouch released close to the shopkeeper is delivered', () {
      expect(flight.reachesShopkeeper(const Offset(120, 310)), isTrue);
    });

    test('a pouch released halfway is not delivered', () {
      expect(flight.reachesShopkeeper(const Offset(250, 300)), isFalse);
    });
  });
}
