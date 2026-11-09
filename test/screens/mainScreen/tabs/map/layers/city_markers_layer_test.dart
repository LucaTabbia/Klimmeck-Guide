import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/config/cloudinary_assets.dart';
import 'package:klimmeck_guide/models/city.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/map/components/city_marker.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/map/layers/city_markers_layer.dart';

import '../../../../../helpers/fixtures/travel_fixtures.dart';
import '../../../../../helpers/landscape.dart';
import '../../../../../helpers/map_harness.dart';
import '../../../../../helpers/svg_cache_seed.dart';

/// Il tipo della fixture è sempre una capitale: la visibilità deve seguire
/// la taglia servita dal BE, non il tipo.
City cityWith({String? type = 'drusteaCapital', String? size}) =>
    City.fromJson({
      ...travelCityJson(
        id: 'city-1',
        name: 'Aldheim',
        markerId: 'city-marker-1',
        marker: departureWire,
        image: null,
      ),
      'type': ?type,
      'size': ?size,
    });

/// Phase 12 D-13c: i marker delle città compaiono per zoom secondo `City.size`.
void main() {
  setUp(
    () =>
        seedSvgCache([CloudinaryAssets.cliffbreak, CloudinaryAssets.talmvere]),
  );

  Future<void> pumpLayer(WidgetTester tester, City city, double zoom) async {
    useLandscapePhone(tester);
    await tester.pumpWidget(
      mapHarness([
        CityMarkersLayer(cities: [city], zoomNotifier: ValueNotifier(zoom)),
      ]),
    );
    await tester.pump();
  }

  testWidgets('a capital is visible from the capital zoom (D-13)', (
    tester,
  ) async {
    await pumpLayer(tester, cityWith(size: 'capital'), 0);

    expect(find.byType(CityMarker), findsOneWidget);
  });

  testWidgets('a city appears only from the city zoom (D-13)', (tester) async {
    final city = cityWith(size: 'city');

    await pumpLayer(tester, city, 2);
    expect(find.byType(CityMarker), findsNothing);

    await pumpLayer(tester, city, 2.5);
    expect(find.byType(CityMarker), findsOneWidget);
  });

  testWidgets('a village appears only from the village zoom (D-13)', (
    tester,
  ) async {
    final city = cityWith(size: 'village');

    await pumpLayer(tester, city, 3);
    expect(find.byType(CityMarker), findsNothing);

    await pumpLayer(tester, city, 3.2);
    expect(find.byType(CityMarker), findsOneWidget);
  });

  testWidgets('a city without a size is hidden (D-13)', (tester) async {
    await pumpLayer(tester, cityWith(), 5);

    expect(find.byType(CityMarker), findsNothing);
  });

  testWidgets('a city without a type is hidden even with a size (D-13)', (
    tester,
  ) async {
    await pumpLayer(tester, cityWith(type: null, size: 'capital'), 5);

    expect(find.byType(CityMarker), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('an always-visible type is shown below its size zoom (D-13)', (
    tester,
  ) async {
    await pumpLayer(
      tester,
      cityWith(type: 'talmvereVillage', size: 'village'),
      0,
    );

    expect(find.byType(CityMarker), findsOneWidget);
  });

  testWidgets('an always-visible type is shown even without a size (D-13)', (
    tester,
  ) async {
    await pumpLayer(tester, cityWith(type: 'talmvereVillage'), 0);

    expect(find.byType(CityMarker), findsOneWidget);
  });

  testWidgets('a regular type still follows City.size (D-13)', (tester) async {
    await pumpLayer(tester, cityWith(size: 'village'), 3);

    expect(find.byType(CityMarker), findsNothing);
  });
}
