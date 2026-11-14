import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/city.dart';
import 'package:klimmeck_guide/models/point_of_interest.dart';
import 'package:klimmeck_guide/models/travel/teleport_destination.dart';
import 'package:latlong2/latlong.dart';

import '../../helpers/fixtures/travel_fixtures.dart';

PointOfInterest poiOf({
  String id = 'poi-ruins-1',
  List<String> types = const ['ruins'],
  double? latitude = 12,
  String? cityId = 'city-talmvere',
}) => PointOfInterest.fromJson(
  pointOfInterestJson(id: id, types: types, latitude: latitude, cityId: cityId),
);

void main() {
  group('placeLabelOf', () {
    test('an inner place is named type presso city (D-29)', () {
      expect(placeLabelOf(poiOf()), 'Rovine presso Talmvere');
    });

    test('a place without a city keeps the type label (D-29)', () {
      expect(placeLabelOf(poiOf(types: ['forest'], cityId: null)), 'Foresta');
    });

    test('all and city are skipped when naming an inner place (D-29)', () {
      expect(
        placeLabelOf(poiOf(types: ['all', 'swamp'])),
        'Palude presso Talmvere',
      );
    });

    test('a city marker is named by its city (D-29)', () {
      expect(placeLabelOf(poiOf(types: ['city'])), 'Talmvere');
    });
  });

  group('TeleportDestination', () {
    test('ofPlace refuses city markers and points without location (D-01)', () {
      expect(TeleportDestination.ofPlace(poiOf(types: ['city'])), isNull);
      expect(TeleportDestination.ofPlace(poiOf(latitude: null)), isNull);
    });

    test(
      'a place with no known type is not a destination, so no dot (D-29)',
      () {
        expect(TeleportDestination.ofPlace(poiOf(types: ['cave'])), isNull);
        expect(TeleportDestination.ofPlace(poiOf(types: ['all'])), isNull);
        expect(
          innerPlacesOf([
            poiOf(id: 'poi-cave', types: ['cave']),
          ]),
          isEmpty,
        );
      },
    );

    test('ofPlace names the inner place and keeps its point (D-01, D-29)', () {
      expect(
        TeleportDestination.ofPlace(poiOf()),
        const TeleportDestination(
          poiId: 'poi-ruins-1',
          point: LatLng(12, 22),
          label: 'Rovine presso Talmvere',
          isCityMarker: false,
          typesLine: 'Rovine\npresso Talmvere',
        ),
      );
    });

    test('ofPlace lists every known type of the place (UAT 2026-11-14)', () {
      expect(
        TeleportDestination.ofPlace(
          poiOf(types: ['all', 'graveyard', 'cave', 'swamp']),
        )?.typesLine,
        'Cimitero · Palude\npresso Talmvere',
      );
      expect(
        TeleportDestination.ofPlace(
          poiOf(types: ['graveyard', 'swamp'], cityId: null),
        )?.typesLine,
        'Cimitero · Palude',
      );
    });

    test('ofCity uses the marker id and point (D-01)', () {
      final city = City.fromJson(
        travelCityJson(id: 'city-talmvere', name: 'Talmvere'),
      );

      final destination = TeleportDestination.ofCity(city);

      expect(destination?.poiId, 'city-marker-2');
      expect(destination?.point, const LatLng(12, 23));
      expect(destination?.isCityMarker, isTrue);
      expect(destination?.label, 'Talmvere');
    });

    test('a city without marker gives no destination (D-01)', () {
      final json = travelCityJson()..remove('markerLocation');

      expect(TeleportDestination.ofCity(City.fromJson(json)), isNull);
      expect(TeleportDestination.ofCity(null), isNull);
    });

    test(
      'innerPlacesOf keeps the served order of inner places only (D-29)',
      () {
        final places = innerPlacesOf([
          poiOf(id: 'poi-swamp', types: ['swamp']),
          poiOf(id: 'poi-marker', types: ['city']),
          poiOf(id: 'poi-nowhere', latitude: null),
          poiOf(id: 'poi-ruins'),
        ]);

        expect(places.map((place) => place.poiId), ['poi-swamp', 'poi-ruins']);
      },
    );

    test('two destinations with the same fields are equal', () {
      const point = LatLng(1, 2);
      expect(
        const TeleportDestination(
          poiId: 'p',
          point: point,
          label: 'Rovine',
          isCityMarker: false,
        ),
        const TeleportDestination(
          poiId: 'p',
          point: point,
          label: 'Rovine',
          isCityMarker: false,
        ),
      );
    });
  });
}
