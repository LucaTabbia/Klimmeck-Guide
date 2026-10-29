import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/config/cloudinary_assets.dart';
import 'package:klimmeck_guide/models/city.dart';
import 'package:klimmeck_guide/models/enums/sex_type.dart';
import 'package:klimmeck_guide/models/point_of_interest.dart';
import 'package:klimmeck_guide/models/travel/teleport_target.dart';
import 'package:klimmeck_guide/repository/innkeeper_failure.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/map/components/city_marker.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/map/components/teleport_mode_chip.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/map/layers/character_marker_layer.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/map/layers/city_markers_layer.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/map/layers/quest_info_overlay.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/map/layers/quest_markers_layer.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/map/layers/quest_paper_layer.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/map/layers/teleport_pawn_layer.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/map/layers/travel_route_layer.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/map/teleportModeCubit/teleport_mode_cubit.dart';
import 'package:klimmeck_guide/shared/components/popup/quest_info_sheet.dart';
import 'package:latlong2/latlong.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/fixtures/quest_fixtures.dart';
import '../../../../helpers/landscape.dart';
import '../../../../helpers/map_harness.dart';
import '../../../../helpers/svg_cache_seed.dart';
import '../../../../helpers/test_app.dart';
import 'world_map_travel_test.dart' hide main;

const LatLng aldheimMarker = LatLng(10, 20);

/// Personaggio scelto dal GM, fermo ad Aldheim come la pedina del GM.
const TeleportTarget bea = TeleportTarget(
  characterId: 'char-bea',
  name: 'Bea',
  location: PointOfInterest(
    id: 'city-marker-1',
    type: null,
    location: aldheimMarker,
    city: null,
    quest: null,
  ),
  sex: SexType.female,
);

const TeleportActive beaActive = TeleportActive(target: bea);

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

  Future<void> pumpTeleportMap(
    WidgetTester tester, {
    TeleportModeState teleportState = beaActive,
  }) => pumpWorldMap(
    tester,
    character: characterLoaded(),
    teleportState: teleportState,
  );

  Future<void> emitTeleport(
    WidgetTester tester,
    TeleportModeState state,
  ) async {
    teleportStates.add(state);
    await tester.pump();
    await tester.pump();
  }

  group('teleport layers (D-15, D-20, C14)', () {
    testWidgets('only the chosen pawn and the cities are on the map', (
      tester,
    ) async {
      await pumpTeleportMap(tester);

      expect(find.byKey(TeleportPawnLayer.pawnKey), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(TeleportPawnLayer.nameLabelKey),
          matching: find.text('Bea'),
        ),
        findsOneWidget,
      );
      expect(find.byKey(CharacterMarkerLayer.pawnKey), findsNothing);
      expect(find.byType(TravelRouteLayer), findsNothing);
      expect(find.byType(QuestMarkersLayer), findsNothing);
      expect(find.byType(QuestPaperLayer), findsNothing);
      expect(find.byType(QuestInfoOverlay), findsNothing);
      expect(find.byType(CityMarkersLayer), findsOneWidget);
      expect(find.byType(TeleportModeChip), findsOneWidget);
    });

    testWidgets('a city in teleport mode opens no lore', (tester) async {
      await pumpTeleportMap(tester);

      final layer = tester.widget<CityMarkersLayer>(
        find.byType(CityMarkersLayer),
      );

      expect(layer.onCityTap, isNull);
      verifyNever(() => worldMapCubit.loadLoreData(any()));
    });

    testWidgets('a failure shows its line on the chip', (tester) async {
      await pumpTeleportMap(
        tester,
        teleportState: const TeleportActive(
          target: bea,
          failure: InnkeeperFailure.questInProgress,
        ),
      );

      expect(find.text('Il personaggio è in una missione in corso'), findsOne);
    });
  });

  group('teleport gestures (D-16, T-10-33)', () {
    testWidgets('«Annulla» cancels the mode once', (tester) async {
      await pumpTeleportMap(tester);

      await tester.tap(find.byKey(TeleportModeChip.cancelKey));
      await tester.pump();

      verify(() => teleportCubit.cancel()).called(1);
    });

    testWidgets('releasing the pawn on a city teleports there', (tester) async {
      await pumpTeleportMap(tester);

      await dragPawnBy(tester, const Offset(300, 0));

      verify(() => teleportCubit.teleportTo(cityB)).called(1);
      verifyNever(
        () => travelCubit.preview(
          characterId: any(named: 'characterId'),
          destination: any(named: 'destination'),
        ),
      );
      expect(mapAvailability.state.isPawnDragging, isFalse);
    });

    testWidgets('a teleport in flight keeps the pawn still', (tester) async {
      await pumpTeleportMap(
        tester,
        teleportState: const TeleportActive(target: bea, isTeleporting: true),
      );

      await dragPawnBy(tester, const Offset(300, 0));

      verifyNever(() => teleportCubit.teleportTo(any()));
    });
  });

  group('teleport availability (C13, T-10-34)', () {
    testWidgets('entering the mode marks the map and leaving restores it', (
      tester,
    ) async {
      await pumpTeleportMap(tester, teleportState: const TeleportIdle());
      expect(mapAvailability.state.isTeleportMode, isFalse);

      await emitTeleport(tester, beaActive);
      expect(mapAvailability.state.isTeleportMode, isTrue);
      expect(find.byKey(TeleportPawnLayer.pawnKey), findsOneWidget);

      await emitTeleport(tester, const TeleportIdle());
      expect(mapAvailability.state.isTeleportMode, isFalse);
      expect(find.byKey(TeleportPawnLayer.pawnKey), findsNothing);
      expect(find.byKey(CharacterMarkerLayer.pawnKey), findsOneWidget);
    });

    testWidgets('leaving the mode during a pawn drag ends the drag', (
      tester,
    ) async {
      await pumpTeleportMap(tester);
      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(TeleportPawnLayer.pawnKey)),
      );
      await gesture.moveBy(const Offset(20, 0));
      await tester.pump();
      await gesture.moveBy(const Offset(20, 0));
      await tester.pump();
      expect(mapAvailability.state.isPawnDragging, isTrue);

      await emitTeleport(tester, const TeleportIdle());

      expect(find.byKey(TeleportPawnLayer.pawnKey), findsNothing);
      expect(mapAvailability.state.isPawnDragging, isFalse);
      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('a map mounted in teleport mode marks it at once', (
      tester,
    ) async {
      await pumpTeleportMap(tester);

      expect(mapAvailability.state.isTeleportMode, isTrue);
      expect(find.byKey(TeleportPawnLayer.pawnKey), findsOneWidget);
      expect(find.byKey(CharacterMarkerLayer.pawnKey), findsNothing);
    });

    testWidgets('entering the mode closes an open quest sheet', (tester) async {
      final enemy = buildQuest(id: 'e-1', type: 'enemy');
      seedSvgCache([CloudinaryAssets.emptySheet]);
      await pumpWorldMap(tester, character: characterLoaded(), quests: [enemy]);
      tester
          .widget<QuestMarkersLayer>(find.byType(QuestMarkersLayer))
          .onQuestSelected(enemy);
      await tester.pumpAndSettle();
      expect(mapAvailability.state.isQuestSheetOpen, isTrue);

      await emitTeleport(tester, beaActive);
      await tester.pumpAndSettle();
      expect(mapAvailability.state.isQuestSheetOpen, isFalse);

      await emitTeleport(tester, const TeleportIdle());
      await tester.pumpAndSettle();
      expect(find.byType(QuestInfoSheet), findsNothing);
    });

    testWidgets('entering the mode centres the camera on the chosen pawn', (
      tester,
    ) async {
      await pumpTeleportMap(tester, teleportState: const TeleportIdle());
      expectCentreAt(tester, const LatLng(0, 0));

      await emitTeleport(tester, beaActive);

      expectCentreAt(tester, aldheimMarker);
    });

    testWidgets('a map mounted in teleport mode centres on the pawn', (
      tester,
    ) async {
      await pumpTeleportMap(tester);

      expectCentreAt(tester, aldheimMarker);
    });
  });
}
