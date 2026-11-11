import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/enums/poi_type.dart';
import 'package:klimmeck_guide/models/point_of_interest.dart';
import 'package:latlong2/latlong.dart';

void main() {
  final poi = PointOfInterest.fromJson({
    'id': 'p',
    'location': [10.0, 20.0],
  });

  test('location is read in the wire order', () {
    expect(poi.location, LatLng(10.0, 20.0));
  });

  test('toJson emits the location in the wire order', () {
    expect(poi.toJson()['location'], [10.0, 20.0]);
  });

  group('lenient parsing (Phase 19)', () {
    PointOfInterest poiWith(Map<String, dynamic> fields) =>
        PointOfInterest.fromJson({'id': 'p', ...fields});

    test('parses a list of known types (D-08)', () {
      final parsed = poiWith({
        'type': ['city', 'dungeon'],
        'location': [1.0, 2.0],
      });

      expect(parsed.type, isA<List<PoiType>>());
      expect(parsed.type, [PoiType.city, PoiType.dungeon]);
    });

    test('drops a type name this client does not know (D-08, D-16)', () {
      final parsed = poiWith({
        'type': ['city', 'demonicPortal'],
        'location': [1.0, 2.0],
      });

      expect(parsed.type, [PoiType.city]);
    });

    test('an empty type list parses to an empty list (D-08)', () {
      final parsed = poiWith({
        'type': <dynamic>[],
        'location': [1.0, 2.0],
      });

      expect(parsed.type, isEmpty);
    });

    test('a type that is not a list is null (D-08)', () {
      for (final Object notAList in ['city', 42]) {
        final parsed = poiWith({
          'type': notAList,
          'location': [1.0, 2.0],
        });

        expect(parsed.type, isNull, reason: '$notAList');
      }
    });

    test('an absent location is null (D-17)', () {
      expect(poiWith({}).location, isNull);
    });

    test('a null location is null (D-17)', () {
      expect(poiWith({'location': null}).location, isNull);
    });

    test('a location whose first element is null is null (D-17)', () {
      for (final nullFirst in [
        [null, 2.0],
        [null],
      ]) {
        expect(
          poiWith({'location': nullFirst}).location,
          isNull,
          reason: '$nullFirst',
        );
      }
    });

    test('a malformed location still throws (D-17)', () {
      for (final Object malformed in [
        [1.0],
        ['a', 'b'],
        [1.0, null],
        <dynamic>[],
        'x',
      ]) {
        expect(
          () => poiWith({'location': malformed}),
          throwsA(anything),
          reason: '$malformed',
        );
      }
    });

    test('toJson writes no quest key (D-06)', () {
      final json = poiWith({
        'location': [1.0, 2.0],
      }).toJson();

      expect(json.keys, isNot(contains('quest')));
    });
  });
}
