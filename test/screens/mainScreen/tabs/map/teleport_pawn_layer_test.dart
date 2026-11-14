import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/config/cloudinary_assets.dart';
import 'package:klimmeck_guide/models/city.dart';
import 'package:klimmeck_guide/models/enums/sex_type.dart';
import 'package:klimmeck_guide/models/point_of_interest.dart';
import 'package:klimmeck_guide/models/travel/teleport_destination.dart';
import 'package:klimmeck_guide/models/travel/teleport_target.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/map/layers/pawn_visuals.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/map/layers/teleport_pawn_layer.dart';
import 'package:latlong2/latlong.dart';

import '../../../../helpers/fixtures/travel_fixtures.dart';
import '../../../../helpers/landscape.dart';
import '../../../../helpers/map_harness.dart';
import '../../../../helpers/svg_cache_seed.dart';

/// Città entrambe nel riquadro dell'harness (zoom 2: ~5,7 px per grado).
final City cityA = City.fromJson(
  travelCityJson(
    id: 'city-1',
    name: 'Aldheim',
    markerId: 'city-marker-1',
    marker: departureWire,
    image: null,
  ),
);

final City cityB = City.fromJson(
  travelCityJson(
    id: 'city-2',
    name: 'Valdoria',
    markerId: 'city-marker-2',
    marker: const [10.0, 60.0],
    image: null,
  ),
);

const LatLng aldheimMarker = LatLng(10, 20);
const LatLng valdoriaMarker = LatLng(10, 60);

const TeleportTarget bea = TeleportTarget(
  characterId: 'char-bea',
  name: 'Bea',
  location: PointOfInterest(
    id: 'city-marker-1',
    type: null,
    location: aldheimMarker,
    city: null,
  ),
  sex: SexType.female,
);

void main() {
  late List<LatLng> dragUpdates;
  late List<TeleportDestination?> drops;

  setUp(() {
    dragUpdates = [];
    drops = [];
    seedSvgCache([CloudinaryAssets.adventurerFemalePawn]);
  });

  Future<MapController> pumpLayer(
    WidgetTester tester, {
    bool canDrag = true,
    List<TeleportDestination> places = const [],
  }) async {
    useLandscapePhone(tester);
    final controller = MapController();
    await tester.pumpWidget(
      mapHarness([
        TeleportPawnLayer(
          target: bea,
          places: places,
          cities: [cityA, cityB],
          zoomNotifier: ValueNotifier(2),
          mapController: controller,
          canDrag: canDrag,
          onDragUpdate: dragUpdates.add,
          onDrop: drops.add,
        ),
      ], controller: controller),
    );
    await tester.pump();
    return controller;
  }

  LatLng pawnPoint(WidgetTester tester) => tester
      .widget<MarkerLayer>(
        find.ancestor(
          of: find.byKey(TeleportPawnLayer.pawnKey),
          matching: find.byType(MarkerLayer),
        ),
      )
      .markers
      .first
      .point;

  group('teleport pawn (D-15, D-20)', () {
    testWidgets('draws only the chosen pawn at the target with its name', (
      tester,
    ) async {
      await pumpLayer(tester);

      expect(find.byKey(TeleportPawnLayer.pawnKey), findsOneWidget);
      expect(pawnPoint(tester), aldheimMarker);
      final label = find.byKey(TeleportPawnLayer.nameLabelKey);
      expect(tester.widget(label), isA<PawnLabel>());
      expect(
        find.descendant(of: label, matching: find.text('Bea')),
        findsOneWidget,
      );
      expect(find.byType(PawnLabel), findsOneWidget);
    });

    testWidgets('the name label ignores pointer events', (tester) async {
      await pumpLayer(tester);

      expect(
        find.descendant(
          of: find.byKey(TeleportPawnLayer.nameLabelKey),
          matching: find.byType(IgnorePointer),
        ),
        findsOneWidget,
      );
    });
  });

  group('teleport drag (D-01, D-29)', () {
    testWidgets('releasing east resolves the nearest city (D-01)', (
      tester,
    ) async {
      await pumpLayer(tester);

      await tester.drag(find.byType(Draggable<Object>), const Offset(200, 0));
      await tester.pumpAndSettle();

      expect(dragUpdates, isNotEmpty);
      expect(drops, [TeleportDestination.ofCity(cityB)]);
      expect(drops.single?.point, valdoriaMarker);
      expect(pawnPoint(tester), aldheimMarker);
    });

    testWidgets('releasing on an inner place reports the place (D-29)', (
      tester,
    ) async {
      const dragOffset = Offset(100, 0);
      final probe = await pumpLayer(tester);
      final camera = probe.camera;
      final ruins = TeleportDestination(
        poiId: 'poi-ruins-1',
        point: camera.screenOffsetToLatLng(
          camera.latLngToScreenOffset(aldheimMarker) + dragOffset,
        ),
        label: 'Rovine presso Aldheim',
        isCityMarker: false,
      );
      await pumpLayer(tester, places: [ruins]);

      await tester.drag(find.byType(Draggable<Object>), dragOffset);
      await tester.pumpAndSettle();

      expect(drops, [ruins]);
    });

    testWidgets('a pawn that cannot be dragged reports nothing', (
      tester,
    ) async {
      await pumpLayer(tester, canDrag: false);

      await tester.drag(find.byType(Draggable<Object>), const Offset(200, 0));
      await tester.pumpAndSettle();

      expect(dragUpdates, isEmpty);
      expect(drops, isEmpty);
    });
  });
}
