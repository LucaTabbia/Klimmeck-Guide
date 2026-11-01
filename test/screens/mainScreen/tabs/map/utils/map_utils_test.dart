import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/city.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/map/layers/pawn_visuals.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/map/utils/map_constants.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/map/utils/map_utils.dart';
import 'package:latlong2/latlong.dart';

import '../../../../../helpers/fixtures/travel_fixtures.dart';

/// L'area di Aldheim sta lontana dal suo marker, vicino a quello di Valdoria:
/// così il test distingue «contiene il punto» da «è la più vicina».
final City aldheim = City.fromJson({
  ...travelCityJson(
    id: 'city-1',
    name: 'Aldheim',
    markerId: 'city-marker-1',
    marker: departureWire,
    image: null,
  ),
  'area': const [
    [0.0, 40.0],
    [0.0, 56.0],
    [20.0, 56.0],
    [20.0, 40.0],
  ],
});

final City valdoria = City.fromJson(
  travelCityJson(
    id: 'city-2',
    name: 'Valdoria',
    markerId: 'city-marker-2',
    marker: const [10.0, 60.0],
    image: null,
  ),
);

void main() {
  group('MapUtils.dropTargetCity (Phase 7 D-01)', () {
    test('a point inside an area picks that city over the nearest', () {
      expect(
        MapUtils.dropTargetCity(const LatLng(10, 55), [aldheim, valdoria]),
        aldheim,
      );
    });

    test('a point outside every area picks the nearest city', () {
      expect(
        MapUtils.dropTargetCity(const LatLng(-30, 22), [aldheim, valdoria]),
        aldheim,
      );
      expect(
        MapUtils.dropTargetCity(const LatLng(-30, 65), [aldheim, valdoria]),
        valdoria,
      );
    });

    test('no cities means no target', () {
      expect(MapUtils.dropTargetCity(const LatLng(10, 55), const []), isNull);
    });
  });

  group('pawnScaleForZoom', () {
    test('scales the pawn with the zoom as the Phase 7 marker did', () {
      expect(
        pawnScaleForZoom(2),
        (2 * 0.05 + 0.4) * 0.08 * MapConstants.characterMarkerSize,
      );
    });
  });
}
