import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/travel/travel_route.dart';
import 'package:latlong2/latlong.dart';

Matcher isPoint(double latitude, double longitude) => isA<LatLng>()
    .having((p) => p.latitude, 'latitude', closeTo(latitude, 1e-9))
    .having((p) => p.longitude, 'longitude', closeTo(longitude, 1e-9));

void main() {
  const a = LatLng(0, 0);
  const b = LatLng(0, 10);
  const c = LatLng(0, 20);

  group('TravelRoute on a straight route', () {
    final route = TravelRoute.of(const [a, b, c]);

    test('measures cumulative and total length', () {
      expect(route.cumulative, [0, 10, 20]);
      expect(route.totalLength, 20);
      expect(route.isEmpty, isFalse);
    });

    test('pointAt interpolates by length and clamps the progress', () {
      expect(route.pointAt(0), a);
      expect(route.pointAt(1), c);
      expect(route.pointAt(0.5), isPoint(0, 10));
      expect(route.pointAt(0.25), isPoint(0, 5));
      expect(route.pointAt(-1), a);
      expect(route.pointAt(2), c);
    });

    test('splitAt(0.25) cuts inside the first segment', () {
      final split = route.splitAt(0.25);
      expect(split.travelled, const [a, LatLng(0, 5)]);
      expect(split.remaining, const [LatLng(0, 5), b, c]);
    });

    test('splitAt(0) leaves the whole route remaining', () {
      final split = route.splitAt(0);
      expect(split.travelled, const [a]);
      expect(split.remaining, const [a, b, c]);
    });

    test('splitAt(1) leaves the whole route travelled', () {
      final split = route.splitAt(1);
      expect(split.travelled, const [a, b, c]);
      expect(split.remaining, const [c]);
    });

    test('splitAt(0.5) exactly on a vertex does not duplicate it', () {
      final split = route.splitAt(0.5);
      expect(split.travelled, const [a, b]);
      expect(split.remaining, const [b, c]);
    });

    test('points and cumulative are unmodifiable', () {
      expect(() => route.points.add(a), throwsUnsupportedError);
      expect(() => route.cumulative.add(0), throwsUnsupportedError);
    });

    test('is equal by points', () {
      expect(TravelRoute.of(const [a, b, c]), route);
      expect(TravelRoute.of(const [a, c]), isNot(route));
    });
  });

  test('uneven segments interpolate by length, not by vertex count', () {
    final route = TravelRoute.of(const [a, LatLng(0, 30), LatLng(10, 30)]);
    expect(route.pointAt(0.75), isPoint(0, 30));
    expect(route.pointAt(0.875), isPoint(5, 30));
  });

  test('a diagonal segment uses the planar length', () {
    final route = TravelRoute.of(const [a, LatLng(3, 4)]);
    expect(route.totalLength, closeTo(5, 1e-9));
    expect(route.pointAt(0.5), isPoint(1.5, 2));
  });

  test('consecutive duplicates are collapsed', () {
    expect(TravelRoute.of(const [a, a, b, b, c]).points, const [a, b, c]);
  });

  test('an empty route never throws', () {
    final route = TravelRoute.of(const []);
    expect(route.isEmpty, isTrue);
    expect(route.totalLength, 0);
    expect(route.pointAt(0.5), isNull);
    final split = route.splitAt(0.5);
    expect(split.travelled, isEmpty);
    expect(split.remaining, isEmpty);
  });

  test('a single point route stays on that point', () {
    for (final route in [
      TravelRoute.of(const [b]),
      TravelRoute.of(const [b, b, b]),
    ]) {
      expect(route.totalLength, 0);
      expect(route.pointAt(0), b);
      expect(route.pointAt(0.5), b);
      expect(route.pointAt(1), b);
      final split = route.splitAt(0.5);
      expect(split.travelled, const [b]);
      expect(split.remaining, const [b]);
    }
  });

  group('travelProgress', () {
    final start = DateTime.utc(2026, 10, 24, 10);

    test('is the elapsed fraction of the duration', () {
      expect(
        travelProgress(
          serverNow: start.add(const Duration(minutes: 30)),
          startTime: start,
          durationMs: 3600000,
        ),
        0.5,
      );
    });

    test('is 0 before the start and 1 after the end', () {
      expect(
        travelProgress(
          serverNow: start.subtract(const Duration(minutes: 5)),
          startTime: start,
          durationMs: 3600000,
        ),
        0,
      );
      expect(
        travelProgress(
          serverNow: start.add(const Duration(hours: 3)),
          startTime: start,
          durationMs: 3600000,
        ),
        1,
      );
    });

    test('a zero or negative duration means arrived', () {
      expect(
        travelProgress(serverNow: start, startTime: start, durationMs: 0),
        1,
      );
      expect(
        travelProgress(serverNow: start, startTime: start, durationMs: -5),
        1,
      );
    });

    test('depends only on the server time it is given', () {
      final early = travelProgress(
        serverNow: start.add(const Duration(minutes: 30)),
        startTime: start,
        durationMs: 4 * 3600000,
      );
      final late = travelProgress(
        serverNow: start.add(const Duration(hours: 2, minutes: 30)),
        startTime: start,
        durationMs: 4 * 3600000,
      );
      expect(early, 0.125);
      expect(late, 0.625);
    });
  });
}
