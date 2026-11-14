import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/travel/teleport_destination.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/map/layers/pawn_visuals.dart';
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
  typesLine: 'Rovine · Cimitero\npresso Aldheim',
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

    testWidgets('a tap on a dot shows every type of the place, a second tap '
        'hides it (UAT 2026-11-14)', (tester) async {
      await pumpLayer(tester, zoom: MapConstants.cityVisibleZoom);
      expect(find.byKey(TeleportPoiLayer.typesLabelKey), findsNothing);

      await tester.tap(find.byKey(TeleportPoiLayer.placeKeyFor(ruins.poiId)));
      await tester.pump();
      expect(
        tester
            .widget<PawnLabel>(find.byKey(TeleportPoiLayer.typesLabelKey))
            .text,
        'Rovine · Cimitero\npresso Aldheim',
      );

      await tester.tap(find.byKey(TeleportPoiLayer.placeKeyFor(ruins.poiId)));
      await tester.pump();
      expect(find.byKey(TeleportPoiLayer.typesLabelKey), findsNothing);
    });

    testWidgets('a place without a types line shows its label', (tester) async {
      await pumpLayer(tester, zoom: MapConstants.cityVisibleZoom);

      await tester.tap(find.byKey(TeleportPoiLayer.placeKeyFor(cave.poiId)));
      await tester.pump();

      expect(
        tester
            .widget<PawnLabel>(find.byKey(TeleportPoiLayer.typesLabelKey))
            .text,
        'Grotta presso Valdoria',
      );
    });

    testWidgets('the tap target of a dot is at least 44 by 44', (tester) async {
      await pumpLayer(tester, zoom: MapConstants.cityVisibleZoom);

      final target = tester.getSize(
        find.ancestor(
          of: find.byKey(TeleportPoiLayer.placeKeyFor(ruins.poiId)),
          matching: find.byType(GestureDetector),
        ),
      );
      expect(target.width, greaterThanOrEqualTo(44));
      expect(target.height, greaterThanOrEqualTo(44));
    });
  });
}
