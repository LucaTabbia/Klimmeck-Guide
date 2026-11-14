import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/travel/teleport_destination.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/map/layers/teleport_poi_layer.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/map/utils/map_constants.dart';
import 'package:latlong2/latlong.dart';

import '../../../../../helpers/landscape.dart';
import '../../../../../helpers/map_harness.dart';

const TeleportDestination ruins = TeleportDestination(
  poiId: 'poi-ruins-1',
  point: LatLng(10, 20),
  label: 'Rovine presso Aldheim',
  isCityMarker: false,
);

const TeleportDestination cave = TeleportDestination(
  poiId: 'poi-cave-1',
  point: LatLng(-10, 40),
  label: 'Grotta presso Valdoria',
  isCityMarker: false,
);

void main() {
  Future<void> pumpLayer(WidgetTester tester, {required double zoom}) async {
    useLandscapePhone(tester);
    await tester.pumpWidget(
      mapHarness([
        TeleportPoiLayer(
          places: const [ruins, cave],
          zoomNotifier: ValueNotifier(zoom),
        ),
      ]),
    );
    await tester.pump();
  }

  group('teleport places layer', () {
    testWidgets('draws one dot per inner place at city zoom (D-29)', (
      tester,
    ) async {
      await pumpLayer(tester, zoom: MapConstants.cityVisibleZoom);

      for (final place in [ruins, cave]) {
        final dot = find.byKey(TeleportPoiLayer.placeKeyFor(place.poiId));
        expect(dot, findsOneWidget);
        expect(
          tester.getSize(dot),
          const Size.square(TeleportPoiLayer.dotSize),
        );
      }
    });

    testWidgets('hides the dots below city zoom (D-29)', (tester) async {
      await pumpLayer(tester, zoom: MapConstants.cityVisibleZoom - 0.1);

      expect(
        find.byKey(TeleportPoiLayer.placeKeyFor(ruins.poiId)),
        findsNothing,
      );
      expect(
        find.byKey(TeleportPoiLayer.placeKeyFor(cave.poiId)),
        findsNothing,
      );
    });

    testWidgets('a dot has no tap (D-29)', (tester) async {
      await pumpLayer(tester, zoom: MapConstants.cityVisibleZoom);

      final dot = find.byKey(TeleportPoiLayer.placeKeyFor(ruins.poiId));
      expect(
        find.descendant(of: dot, matching: find.byType(GestureDetector)),
        findsNothing,
      );
      expect(
        find.descendant(of: dot, matching: find.byType(InkWell)),
        findsNothing,
      );
    });
  });
}
