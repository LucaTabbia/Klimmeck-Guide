import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/wire_lat_lng.dart';
import 'package:latlong2/latlong.dart';

void main() {
  group('latLngFromWire', () {
    test('reads [a, b] as LatLng(a, b) with no swap (C1)', () {
      expect(latLngFromWire([10.0, 20.0]), LatLng(10.0, 20.0));
    });

    test('accepts integers', () {
      expect(latLngFromWire([10, 20]), LatLng(10.0, 20.0));
    });
  });

  group('tryLatLngFromWire', () {
    for (final malformed in <Object?>[
      null,
      'x',
      <double>[],
      [1.0],
      ['a', 2.0],
      [91.0, 0.0],
      [0.0, 181.0],
    ]) {
      test('returns null for $malformed', () {
        expect(tryLatLngFromWire(malformed), isNull);
      });
    }

    test('ignores extra items of a valid point', () {
      expect(tryLatLngFromWire([10.0, 20.0, 99.0]), LatLng(10.0, 20.0));
    });
  });
}
