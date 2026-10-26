import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/config/cloudinary_assets.dart';
import 'package:klimmeck_guide/models/character/character.dart';
import 'package:klimmeck_guide/models/city.dart';
import 'package:klimmeck_guide/models/travel/active_travel.dart';
import 'package:klimmeck_guide/models/travel/travel_preview.dart';
import 'package:klimmeck_guide/models/travel/travel_route.dart';
import 'package:klimmeck_guide/screens/mainScreen/characterCubit/character_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/map/layers/character_marker_layer.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/map/travelProgressCubit/travel_progress_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/travelCubit/travel_cubit.dart';
import 'package:latlong2/latlong.dart';

import '../../../../helpers/fixtures/quest_fixtures.dart';
import '../../../../helpers/fixtures/travel_fixtures.dart';
import '../../../../helpers/landscape.dart';
import '../../../../helpers/map_harness.dart';
import '../../../../helpers/mocks.dart';
import '../../../../helpers/svg_cache_seed.dart';

/// Città entrambe nel riquadro dell'harness (zoom 2: ~5,7 px per grado).
final City cityA = City.fromJson({
  ...travelCityJson(
    id: 'city-1',
    name: 'Aldheim',
    markerId: 'city-marker-1',
    marker: departureWire,
    image: null,
  ),
  'type': 'drusteaCapital',
});

final City cityB = City.fromJson({
  ...travelCityJson(
    id: 'city-2',
    name: 'Valdoria',
    markerId: 'city-marker-2',
    marker: const [10.0, 60.0],
    image: null,
  ),
  'type': 'drusteaCapital',
});

const LatLng home = LatLng(10, 20);
const LatLng destination = LatLng(10, 60);

CharacterLoaded characterLoaded({
  Map<String, dynamic>? activeTravel,
  Map<String, dynamic>? pendingQuest,
}) => CharacterLoaded(
  Character.fromJson(
    travellingCharacterJson(
      activeTravel: activeTravel,
      pendingQuest: pendingQuest,
    ),
  ),
);

final TravelPreview preview = TravelPreview.fromJson(travelPreviewJson());
final DateTime eta = DateTime.utc(2026, 10, 24, 12, 40);
final DateTime previewedAt = DateTime.utc(2026, 10, 24, 10);

TravelConfirming confirming() => TravelConfirming(
  destination: cityB,
  preview: preview,
  eta: eta,
  previewedAt: previewedAt,
);

const LatLng midRoad = LatLng(11, 21);

TravelProgressActive travelling({
  LatLng? position = midRoad,
  Duration remainingTime = const Duration(hours: 1, minutes: 12),
  bool isArriving = false,
}) => TravelProgressActive(
  travel: ActiveTravel.fromJson(activeTravelJson()),
  route: TravelRoute.of(const [home, midRoad, LatLng(12, 23)]),
  position: position,
  travelled: const [home, midRoad],
  remaining: const [midRoad, LatLng(12, 23)],
  remainingTime: remainingTime,
  isArriving: isArriving,
  arrivalRefetchCount: 0,
);

void main() {
  late MockCharacterCubit characterCubit;
  late MockTravelCubit travelCubit;
  late MockTravelProgressCubit progressCubit;
  late StreamController<CharacterState> characterStates;
  late StreamController<TravelState> travelStates;
  late StreamController<TravelProgressState> progressStates;
  late List<(LatLng?, City?)> dragEnds;

  setUp(() {
    characterCubit = MockCharacterCubit();
    travelCubit = MockTravelCubit();
    progressCubit = MockTravelProgressCubit();
    characterStates = StreamController<CharacterState>.broadcast();
    travelStates = StreamController<TravelState>.broadcast();
    progressStates = StreamController<TravelProgressState>.broadcast();
    dragEnds = [];
    seedSvgCache([CloudinaryAssets.adventurerMalePawn]);
  });

  tearDown(() async {
    await characterStates.close();
    await travelStates.close();
    await progressStates.close();
  });

  Future<void> pumpLayer(
    WidgetTester tester, {
    required CharacterState character,
    TravelState travel = const TravelIdle(),
    TravelProgressState progress = const TravelProgressIdle(),
  }) async {
    useLandscapePhone(tester);
    whenListen(characterCubit, characterStates.stream, initialState: character);
    whenListen(travelCubit, travelStates.stream, initialState: travel);
    whenListen(progressCubit, progressStates.stream, initialState: progress);
    final controller = MapController();
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<CharacterCubit>.value(value: characterCubit),
          BlocProvider<TravelCubit>.value(value: travelCubit),
          BlocProvider<TravelProgressCubit>.value(value: progressCubit),
        ],
        child: mapHarness([
          CharacterMarkerLayer(
            cities: [cityA, cityB],
            zoomNotifier: ValueNotifier(2),
            mapController: controller,
            bounds: LatLngBounds(
              const LatLng(-90, -180),
              const LatLng(90, 180),
            ),
            onDragUpdate: (_) {},
            onDragEnd: (location, city) => dragEnds.add((location, city)),
          ),
        ], controller: controller),
      ),
    );
    await tester.pump();
  }

  LatLng pawnPoint(WidgetTester tester) => tester
      .widget<MarkerLayer>(
        find.ancestor(
          of: find.byKey(CharacterMarkerLayer.pawnKey),
          matching: find.byType(MarkerLayer),
        ),
      )
      .markers
      .first
      .point;

  Draggable<Object> pawnDraggable(WidgetTester tester) =>
      tester.widget<Draggable<Object>>(find.byType(Draggable<Object>));

  group('free and blocked pawn (D-01)', () {
    testWidgets('a free character can drag the pawn from its location', (
      tester,
    ) async {
      await pumpLayer(tester, character: characterLoaded());

      expect(find.byType(Draggable<Object>), findsOneWidget);
      expect(pawnDraggable(tester).maxSimultaneousDrags, isNull);
      expect(pawnPoint(tester), home);
    });

    testWidgets('a pending quest blocks the drag', (tester) async {
      await pumpLayer(
        tester,
        character: characterLoaded(pendingQuest: laneJson()),
      );

      expect(pawnDraggable(tester).maxSimultaneousDrags, 0);
      expect(pawnPoint(tester), home);
    });
  });

  group('confirming pawn (D-02, D-04)', () {
    testWidgets('previewing holds the pawn on the destination', (tester) async {
      await pumpLayer(
        tester,
        character: characterLoaded(),
        travel: TravelPreviewing(cityB),
      );

      expect(pawnPoint(tester), destination);
      expect(pawnDraggable(tester).maxSimultaneousDrags, 0);
    });

    testWidgets('confirming holds the pawn on the destination', (tester) async {
      await pumpLayer(
        tester,
        character: characterLoaded(),
        travel: confirming(),
      );

      expect(pawnPoint(tester), destination);
      expect(pawnDraggable(tester).maxSimultaneousDrags, 0);
    });

    testWidgets('starting holds the pawn on the destination', (tester) async {
      await pumpLayer(
        tester,
        character: characterLoaded(),
        travel: TravelStarting(
          destination: cityB,
          preview: preview,
          eta: eta,
          previewedAt: previewedAt,
        ),
      );

      expect(pawnPoint(tester), destination);
      expect(pawnDraggable(tester).maxSimultaneousDrags, 0);
    });

    testWidgets('started puts the pawn home until the travel arrives', (
      tester,
    ) async {
      await pumpLayer(
        tester,
        character: characterLoaded(),
        travel: TravelStarted(destination: cityB, preview: preview),
      );

      expect(pawnPoint(tester), home);
      expect(pawnDraggable(tester).maxSimultaneousDrags, 0);
    });

    testWidgets(
      'an unrelated character event keeps the pawn on the destination',
      (tester) async {
        await pumpLayer(
          tester,
          character: characterLoaded(),
          travel: confirming(),
        );

        final withAssets = Character.fromJson({
          ...travellingCharacterJson(),
          'assets': {'ownedItems': const []},
        });
        characterStates.add(CharacterLoaded(withAssets));
        await tester.pump();
        await tester.pump();

        expect(pawnPoint(tester), destination);
      },
    );

    testWidgets('going back to idle springs the pawn home', (tester) async {
      await pumpLayer(
        tester,
        character: characterLoaded(),
        travel: confirming(),
      );

      travelStates.add(const TravelIdle());
      await tester.pump();
      await tester.pump();

      expect(pawnPoint(tester), home);
      expect(pawnDraggable(tester).maxSimultaneousDrags, isNull);
    });
  });

  group('drag release (D-01)', () {
    testWidgets('releasing east resolves the nearest city', (tester) async {
      await pumpLayer(tester, character: characterLoaded());

      await tester.drag(find.byType(Draggable<Object>), const Offset(200, 0));
      await tester.pumpAndSettle();

      expect(dragEnds, [(destination, cityB)]);
      expect(pawnPoint(tester), home);
    });
  });

  group('travelling pawn (D-08, D-10, D-13)', () {
    Finder labelText(String text) => find.descendant(
      of: find.byKey(CharacterMarkerLayer.travelLabelKey),
      matching: find.text(text),
    );

    testWidgets('sits on the road with the remaining time and no gestures', (
      tester,
    ) async {
      await pumpLayer(
        tester,
        character: characterLoaded(activeTravel: activeTravelJson()),
        progress: travelling(),
      );

      expect(pawnPoint(tester), midRoad);
      expect(labelText('1 h 12 min'), findsOneWidget);
      expect(find.byType(Draggable<Object>), findsNothing);
      expect(
        find.descendant(
          of: find.byKey(CharacterMarkerLayer.pawnKey),
          matching: find.byType(GestureDetector),
        ),
        findsNothing,
      );
    });

    testWidgets('reads arriving at the end of the road', (tester) async {
      await pumpLayer(
        tester,
        character: characterLoaded(activeTravel: activeTravelJson()),
        progress: travelling(
          position: const LatLng(12, 23),
          remainingTime: Duration.zero,
          isArriving: true,
        ),
      );

      expect(pawnPoint(tester), const LatLng(12, 23));
      expect(labelText('In arrivo…'), findsOneWidget);
    });

    testWidgets('an empty road keeps the pawn home with the label', (
      tester,
    ) async {
      await pumpLayer(
        tester,
        character: characterLoaded(activeTravel: activeTravelJson()),
        progress: travelling(position: null),
      );

      expect(pawnPoint(tester), home);
      expect(find.byKey(CharacterMarkerLayer.travelLabelKey), findsOneWidget);
    });

    testWidgets('an automatic quest travel looks like a free one', (
      tester,
    ) async {
      await pumpLayer(
        tester,
        character: characterLoaded(
          activeTravel: activeTravelJson(),
          pendingQuest: laneJson(startDate: null),
        ),
        progress: travelling(),
      );

      expect(pawnPoint(tester), midRoad);
      expect(labelText('1 h 12 min'), findsOneWidget);
      expect(find.byType(Draggable<Object>), findsNothing);
    });

    testWidgets('snaps to the new location when the backend ends the travel', (
      tester,
    ) async {
      await pumpLayer(
        tester,
        character: characterLoaded(activeTravel: activeTravelJson()),
        progress: travelling(isArriving: true),
      );

      characterStates.add(
        CharacterLoaded(
          Character.fromJson(
            travellingCharacterJson(
              locationId: 'city-marker-2',
              location: const [10.0, 60.0],
            ),
          ),
        ),
      );
      progressStates.add(const TravelProgressIdle());
      await tester.pump();
      await tester.pump();

      expect(pawnPoint(tester), destination);
      expect(find.byKey(CharacterMarkerLayer.travelLabelKey), findsNothing);
    });
  });
}
