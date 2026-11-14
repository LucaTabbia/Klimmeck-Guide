import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/city.dart';
import 'package:klimmeck_guide/models/travel/teleport_destination.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/map/utils/map_utils.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/map/utils/teleport_drop.dart';
import 'package:latlong2/latlong.dart';

import '../../../../../helpers/fixtures/travel_fixtures.dart';

/// Proiezione finta: 10 pixel per grado su entrambi gli assi.
Offset toScreen(LatLng point) =>
    Offset(point.longitude * 10, point.latitude * 10);

TeleportDestination placeAt(String poiId, LatLng point) => TeleportDestination(
  poiId: poiId,
  point: point,
  label: 'Rovine presso Talmvere',
  isCityMarker: false,
);

final City aldheim = City.fromJson(
  travelCityJson(
    id: 'city-1',
    name: 'Aldheim',
    markerId: 'city-marker-1',
    marker: const [0.0, 20.0],
    image: null,
  ),
);

final City valdoria = City.fromJson(
  travelCityJson(
    id: 'city-2',
    name: 'Valdoria',
    markerId: 'city-marker-2',
    marker: const [0.0, -20.0],
    image: null,
  ),
);

void main() {
  final ruins = placeAt('poi-ruins-1', const LatLng(0, 0));
  final cave = placeAt('poi-cave-1', const LatLng(0, 2));

  TeleportDestination? dropAt(
    LatLng releasePoint, {
    List<TeleportDestination> places = const [],
    List<City> cities = const [],
  }) => teleportDropTarget(
    releasePoint: releasePoint,
    places: places,
    cities: cities,
    toScreen: toScreen,
  );

  group('teleportDropTarget', () {
    test('a release within 32 px of an inner place drops on it (D-29)', () {
      final target = dropAt(
        const LatLng(0, 3),
        places: [ruins],
        cities: [aldheim, valdoria],
      );

      expect(target, ruins);
    });

    test('the nearest of two close places wins (D-29)', () {
      final target = dropAt(
        const LatLng(0, 1.5),
        places: [ruins, cave],
        cities: [aldheim, valdoria],
      );

      expect(target, cave);
    });

    test('a release farther than 32 px falls back to the city rule as a '
        'city-marker destination (D-01)', () {
      const releasePoint = LatLng(0, 10);
      final cities = [aldheim, valdoria];

      final target = dropAt(releasePoint, places: [ruins], cities: cities);

      expect(
        target,
        TeleportDestination.ofCity(
          MapUtils.dropTargetCity(releasePoint, cities),
        ),
      );
      expect(target?.poiId, 'city-marker-1');
      expect(target?.isCityMarker, isTrue);
    });

    test('without places the city rule applies (D-01)', () {
      final target = dropAt(const LatLng(0, -15), cities: [aldheim, valdoria]);

      expect(target, TeleportDestination.ofCity(valdoria));
    });

    test('without cities and places the result is null', () {
      expect(dropAt(const LatLng(0, 0)), isNull);
    });
  });
}
