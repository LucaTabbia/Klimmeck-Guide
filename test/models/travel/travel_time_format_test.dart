import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/travel/travel_time_format.dart';

void main() {
  group('formatTravelDuration', () {
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
        expect(formatTravelDuration(duration), expected);
      });
    });
  });

  group('formatTravelDistance', () {
    final cases = <double, String>{
      15.8: '15,8 km',
      0.37: '0,4 km',
      99.94: '99,9 km',
      204.0: '204 km',
      506.4: '506 km',
    };

    cases.forEach((km, expected) {
      test('$km reads "$expected"', () {
        expect(formatTravelDistance(km), expected);
      });
    });
  });

  group('formatArrival', () {
    final now = DateTime(2026, 10, 24, 14, 0);

    test('today', () {
      expect(
        formatArrival(DateTime(2026, 10, 24, 16, 40), serverNow: now),
        'oggi alle 16:40',
      );
    });

    test('tomorrow', () {
      expect(
        formatArrival(DateTime(2026, 10, 25, 9, 10), serverNow: now),
        'domani alle 09:10',
      );
    });

    test('a later day shows the date', () {
      expect(
        formatArrival(DateTime(2026, 10, 27, 9, 5), serverNow: now),
        'il 27/10 alle 09:05',
      );
    });

    test('tomorrow across the month end', () {
      expect(
        formatArrival(
          DateTime(2026, 11, 1, 1, 0),
          serverNow: DateTime(2026, 10, 31, 23, 0),
        ),
        'domani alle 01:00',
      );
    });

    test('a UTC arrival is shown in local time', () {
      final utc = DateTime.utc(2026, 10, 24, 16, 40);
      expect(
        formatArrival(utc, serverNow: now),
        formatArrival(utc.toLocal(), serverNow: now),
      );
    });
  });

  test('travelArrivingLabel uses the single-character ellipsis', () {
    expect(travelArrivingLabel, 'In arrivo…');
  });
}
