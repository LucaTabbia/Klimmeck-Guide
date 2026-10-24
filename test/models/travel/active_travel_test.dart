import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/travel/active_travel.dart';

import '../../helpers/fixtures/travel_fixtures.dart';

void main() {
  final travel = ActiveTravel.fromJson(activeTravelJson());

  test('fromJson reads dates, duration, destination id and road', () {
    expect(travel.startTime, DateTime.utc(2026, 10, 24, 10));
    expect(travel.endTime, DateTime.utc(2026, 10, 24, 12, 40));
    expect(travel.duration, 9600000);
    expect(travel.to, isA<String>());
    expect(travel.to, 'city-marker-2');
    expect(travel.road.points, hasLength(3));
  });

  test('toJson round trips with UTC ISO dates', () {
    final json = travel.toJson();
    expect(json['startTime'], '2026-10-24T10:00:00.000Z');
    expect(json['endTime'], '2026-10-24T12:40:00.000Z');
    expect(ActiveTravel.fromJson(json), travel);
  });

  test('equality covers every field', () {
    expect(travel, ActiveTravel.fromJson(activeTravelJson()));
    expect(
      travel == ActiveTravel.fromJson(activeTravelJson(to: 'other')),
      isFalse,
    );
  });

  group('tryFromJson', () {
    final malformed = <String, Object?>{
      'null': null,
      'a non-map': 'x',
      'no startTime': activeTravelJson()..remove('startTime'),
      'a bad startTime': activeTravelJson(startTime: 'not-a-date'),
      'a bad duration': activeTravelJson()..['duration'] = 'x',
      'no road': activeTravelJson()..remove('road'),
    };
    malformed.forEach((label, json) {
      test('returns null for $label', () {
        expect(ActiveTravel.tryFromJson(json), isNull);
      });
    });

    test('parses a valid travel', () {
      expect(ActiveTravel.tryFromJson(activeTravelJson()), travel);
    });
  });
}
