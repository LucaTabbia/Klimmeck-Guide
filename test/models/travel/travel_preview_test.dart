import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/travel/travel_preview.dart';

import '../../helpers/fixtures/travel_fixtures.dart';

void main() {
  final preview = TravelPreview.fromJson(travelPreviewJson());

  test('fromJson reads distance, duration and road', () {
    expect(preview.distance, 15.8);
    expect(preview.duration, 9600000);
    expect(preview.road.points, hasLength(3));
  });

  test('toJson round trips', () {
    expect(TravelPreview.fromJson(preview.toJson()), preview);
  });

  test('equality covers every field', () {
    expect(preview, TravelPreview.fromJson(travelPreviewJson()));
    expect(
      preview == TravelPreview.fromJson(travelPreviewJson(duration: 1)),
      isFalse,
    );
  });

  group('food and life (BE Phase 14)', () {
    final fedPreview = TravelPreview.fromJson(
      travelPreviewJson(
        food: [
          travelFoodItemJson(),
          travelFoodItemJson(id: 'loot-apple', name: 'Mela selvatica'),
        ],
        hpLost: 12,
        arrivesAlive: false,
      ),
    );

    test(
      'reads the food, the life lost and arrivesAlive from the backend (D-01)',
      () {
        final parsed = TravelPreview.fromJson(
          travelPreviewJson(
            food: [
              travelFoodItemJson(),
              travelFoodItemJson(id: 'loot-apple', name: 'Mela selvatica'),
            ],
            hpLost: 136,
            arrivesAlive: false,
          ),
        );

        expect(parsed.food.map((entry) => entry.name), [
          'Razione da viaggio',
          'Mela selvatica',
        ]);
        expect(parsed.hpLost, 136);
        expect(parsed.arrivesAlive, isFalse);
      },
    );

    test(
      'reads a missing food, hpLost and arrivesAlive as no food, 0 and true (D-01)',
      () {
        expect(preview.food, isEmpty);
        expect(preview.hpLost, 0);
        expect(preview.arrivesAlive, isTrue);
      },
    );

    test('drops a malformed food entry and keeps the preview (D-01)', () {
      final parsed = TravelPreview.fromJson(
        travelPreviewJson(
          food: [
            travelFoodItemJson(),
            {'quantity': 1},
          ],
        ),
      );

      expect(parsed.food, hasLength(1));
      expect(parsed.distance, 15.8);
    });

    test(
      'reads a non-numeric hpLost as 0 and a non-boolean arrivesAlive as true (D-01)',
      () {
        final garbled = TravelPreview.fromJson({
          ...travelPreviewJson(),
          'hpLost': '136',
          'arrivesAlive': 'no',
        });
        final decimal = TravelPreview.fromJson({
          ...travelPreviewJson(),
          'hpLost': 136.0,
        });

        expect(garbled.hpLost, 0);
        expect(garbled.arrivesAlive, isTrue);
        expect(decimal.hpLost, 136);
      },
    );

    test('round-trips the food fields through toJson (D-01)', () {
      expect(TravelPreview.fromJson(fedPreview.toJson()), fedPreview);
    });

    test('differs by food, hpLost and arrivesAlive (D-01)', () {
      final base = TravelPreview.fromJson(
        travelPreviewJson(
          food: [travelFoodItemJson()],
          hpLost: 12,
          arrivesAlive: true,
        ),
      );
      final otherFood = TravelPreview.fromJson(
        travelPreviewJson(
          food: [travelFoodItemJson(quantity: 2)],
          hpLost: 12,
          arrivesAlive: true,
        ),
      );
      final otherHp = TravelPreview.fromJson(
        travelPreviewJson(
          food: [travelFoodItemJson()],
          hpLost: 13,
          arrivesAlive: true,
        ),
      );
      final otherArrival = TravelPreview.fromJson(
        travelPreviewJson(
          food: [travelFoodItemJson()],
          hpLost: 12,
          arrivesAlive: false,
        ),
      );

      expect(base == otherFood, isFalse);
      expect(base == otherHp, isFalse);
      expect(base == otherArrival, isFalse);
    });
  });
}
