import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/config/cloudinary_assets.dart';
import 'package:klimmeck_guide/models/city.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/map/components/city_marker.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/map/layers/city_markers_layer.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/landscape.dart';
import '../../../../helpers/map_harness.dart';
import '../../../../helpers/svg_cache_seed.dart';
import '../../../../helpers/test_app.dart';
import 'world_map_travel_test.dart' hide main;

/// Phase 10 ADMIN-04: la Mappa in modalità teletrasporto del GM.
void main() {
  setUpWorldMapHarness();

  setUp(() => seedSvgCache([CloudinaryAssets.adventurerFemalePawn]));

  Finder cityMarkerOf(City city) => find.byWidgetPredicate(
    (widget) => widget is CityMarker && widget.city.id == city.id,
  );

  group('city lore tap (10-CONTEXT C14)', () {
    Future<void> pumpMarker(WidgetTester tester, VoidCallback? onTap) =>
        tester.pumpWidget(
          buildTestApp(
            home: Center(
              child: CityMarker(city: cityA, onTap: onTap),
            ),
          ),
        );

    testWidgets('a marker without a callback ignores the tap', (tester) async {
      await pumpMarker(tester, null);

      await tester.tap(find.byType(CityMarker));
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets('a marker with a callback calls it once per tap', (
      tester,
    ) async {
      var taps = 0;
      await pumpMarker(tester, () => taps++);

      await tester.tap(find.byType(CityMarker));
      await tester.pump();

      expect(taps, 1);
    });

    Future<void> pumpLayer(
      WidgetTester tester,
      void Function(City city)? onCityTap,
    ) async {
      useLandscapePhone(tester);
      await tester.pumpWidget(
        mapHarness([
          CityMarkersLayer(
            cities: [cityA],
            zoomNotifier: ValueNotifier(2),
            onCityTap: onCityTap,
          ),
        ]),
      );
      await tester.pump();
    }

    testWidgets('the layer hands the tapped city to its callback', (
      tester,
    ) async {
      final tapped = <City>[];
      await pumpLayer(tester, tapped.add);

      await tester.tap(cityMarkerOf(cityA));
      await tester.pump();

      expect(tapped, [cityA]);
    });

    testWidgets('the layer without a callback leaves the markers inert', (
      tester,
    ) async {
      await pumpLayer(tester, null);

      await tester.tap(cityMarkerOf(cityA));
      // Il tap passa alla mappa, che attende un eventuale doppio tap.
      await tester.pump(const Duration(seconds: 1));

      expect(tester.takeException(), isNull);
      expect(tester.widget<CityMarker>(cityMarkerOf(cityA)).onTap, isNull);
    });

    testWidgets('outside teleport mode a city opens its lore', (tester) async {
      when(() => worldMapCubit.loadLoreData(any())).thenAnswer((_) async {});
      await pumpWorldMap(tester, character: characterLoaded());

      tester.widget<CityMarkersLayer>(find.byType(CityMarkersLayer)).onCityTap!(
        cityB,
      );
      await tester.pump();

      verify(() => worldMapCubit.loadLoreData('lore-city-2')).called(1);
    });
  });
}
