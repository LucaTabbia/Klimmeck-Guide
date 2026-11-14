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
import 'package:klimmeck_guide/screens/mainScreen/tabs/map/layers/pawn_visuals.dart';
import 'package:klimmeck_guide/screens/mainScreen/questAcceptanceCubit/quest_acceptance_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/characterCubit/character_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/prisonCubit/prison_cubit.dart';
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
  'size': 'capital',
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
  'size': 'capital',
});

const LatLng home = LatLng(10, 20);
const LatLng destination = LatLng(10, 60);

CharacterLoaded characterLoaded({
  String locationId = 'city-marker-1',
  Map<String, dynamic>? activeTravel,
  Map<String, dynamic>? pendingQuest,
  Map<String, dynamic>? awaitingAid,
  bool? missionInProgress,
  bool? guidedMissionInProgress,
}) => CharacterLoaded(
  Character.fromJson(
    travellingCharacterJson(
      locationId: locationId,
      activeTravel: activeTravel,
      pendingQuest: pendingQuest,
      awaitingAid: awaitingAid,
      missionInProgress: missionInProgress,
      guidedMissionInProgress: guidedMissionInProgress,
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
  late MockPrisonCubit prisonCubit;
  late MockQuestAcceptanceCubit acceptanceCubit;
  late StreamController<PrisonState> prisonStates;
  late StreamController<CharacterState> characterStates;
  late StreamController<TravelState> travelStates;
  late StreamController<TravelProgressState> progressStates;
  late List<(LatLng?, City?)> dragEnds;
  late List<City> tapped;

  setUp(() {
    characterCubit = MockCharacterCubit();
    travelCubit = MockTravelCubit();
    progressCubit = MockTravelProgressCubit();
    prisonCubit = MockPrisonCubit();
    acceptanceCubit = MockQuestAcceptanceCubit();
    prisonStates = StreamController<PrisonState>.broadcast();
    characterStates = StreamController<CharacterState>.broadcast();
    travelStates = StreamController<TravelState>.broadcast();
    progressStates = StreamController<TravelProgressState>.broadcast();
    dragEnds = [];
    tapped = [];
    seedSvgCache([CloudinaryAssets.adventurerMalePawn]);
  });

  tearDown(() async {
    await characterStates.close();
    await travelStates.close();
    await progressStates.close();
    await prisonStates.close();
  });

  Future<void> pumpLayer(
    WidgetTester tester, {
    required CharacterState character,
    TravelState travel = const TravelIdle(),
    TravelProgressState progress = const TravelProgressIdle(),
    PrisonState prison = const PrisonState(null),
    QuestAcceptanceState acceptance = const QuestAcceptanceIdle(),
    double zoom = 2,
  }) async {
    useLandscapePhone(tester);
    whenListen(prisonCubit, prisonStates.stream, initialState: prison);
    whenListen(
      acceptanceCubit,
      const Stream<QuestAcceptanceState>.empty(),
      initialState: acceptance,
    );
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
          BlocProvider<PrisonCubit>.value(value: prisonCubit),
          BlocProvider<QuestAcceptanceCubit>.value(value: acceptanceCubit),
        ],
        child: mapHarness([
          CharacterMarkerLayer(
            cities: [cityA, cityB],
            zoomNotifier: ValueNotifier(zoom),
            mapController: controller,
            bounds: LatLngBounds(
              const LatLng(-90, -180),
              const LatLng(90, 180),
            ),
            onDragUpdate: (_) {},
            onDragEnd: (location, city) => dragEnds.add((location, city)),
            onCityTap: tapped.add,
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

  group('quest being accepted (utente 2026-11-14)', () {
    testWidgets('shows «In preparazione…» over a pawn that cannot be dragged '
        'while the server answers', (tester) async {
      await pumpLayer(
        tester,
        character: characterLoaded(),
        acceptance: const QuestAccepting('h-1'),
      );

      expect(
        tester
            .widget<PawnLabel>(
              find.byKey(CharacterMarkerLayer.preparingLabelKey),
            )
            .text,
        'In preparazione…',
      );
      expect(pawnDraggable(tester).maxSimultaneousDrags, 0);
    });

    testWidgets('shows no preparation label otherwise', (tester) async {
      await pumpLayer(tester, character: characterLoaded());

      expect(find.byKey(CharacterMarkerLayer.preparingLabelKey), findsNothing);
    });
  });

  group('label distance (UAT 2026-11-14)', () {
    for (final zoom in [1.0, 4.0, 8.0]) {
      testWidgets('the label floats 10 px over the pawn at zoom $zoom', (
        tester,
      ) async {
        await pumpLayer(
          tester,
          character: characterLoaded(
            missionInProgress: true,
            guidedMissionInProgress: true,
          ),
          zoom: zoom,
        );

        final pawn = tester.getRect(find.byKey(CharacterMarkerLayer.pawnKey));
        final label = tester.getRect(
          find.descendant(
            of: find.byKey(CharacterMarkerLayer.missionLabelKey),
            matching: find.byType(DecoratedBox),
          ),
        );
        expect(pawn.top - label.bottom, moreOrLessEquals(10, epsilon: 0.5));
        expect(label.center.dx, moreOrLessEquals(pawn.center.dx, epsilon: 0.5));
      });
    }
  });

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

  group('wounded pawn (Phase 9 D-16)', () {
    testWidgets('awaiting aid shows the label and blocks the drag', (
      tester,
    ) async {
      await pumpLayer(
        tester,
        character: characterLoaded(awaitingAid: awaitingAidJson()),
      );

      expect(pawnDraggable(tester).maxSimultaneousDrags, 0);
      expect(
        find.descendant(
          of: find.byKey(CharacterMarkerLayer.awaitingAidLabelKey),
          matching: find.text('In attesa di soccorso'),
        ),
        findsOneWidget,
      );
      expect(find.byKey(CharacterMarkerLayer.travelLabelKey), findsNothing);
      expect(pawnPoint(tester), home);
    });

    testWidgets('the awaiting-aid label ignores pointer events', (
      tester,
    ) async {
      await pumpLayer(
        tester,
        character: characterLoaded(awaitingAid: awaitingAidJson()),
      );

      expect(
        find.descendant(
          of: find.byKey(CharacterMarkerLayer.awaitingAidLabelKey),
          matching: find.byType(IgnorePointer),
        ),
        findsOneWidget,
      );
    });

    testWidgets('a free character shows no awaiting-aid label', (tester) async {
      await pumpLayer(tester, character: characterLoaded());

      expect(
        find.byKey(CharacterMarkerLayer.awaitingAidLabelKey),
        findsNothing,
      );
      expect(pawnDraggable(tester).maxSimultaneousDrags, isNull);
    });
  });

  group('prison (quick 261110-cgd)', () {
    const imprisoned = PrisonState(Duration(hours: 9));

    testWidgets('«In prigione» floats over the pawn and the drag is blocked '
        '(quick 261110-cgd)', (tester) async {
      await pumpLayer(tester, character: characterLoaded(), prison: imprisoned);

      expect(pawnDraggable(tester).maxSimultaneousDrags, 0);
      expect(
        find.descendant(
          of: find.byKey(CharacterMarkerLayer.prisonLabelKey),
          matching: find.text('In prigione per: 9 h'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(CharacterMarkerLayer.prisonLabelKey),
          matching: find.byType(IgnorePointer),
        ),
        findsOneWidget,
      );
    });

    testWidgets('the marker follows the remaining time', (tester) async {
      await pumpLayer(tester, character: characterLoaded(), prison: imprisoned);

      prisonStates.add(const PrisonState(Duration(hours: 8, minutes: 59)));
      await tester.pump();
      await tester.pump();

      expect(find.text('In prigione per: 8 h 59 min'), findsOneWidget);
    });

    testWidgets('at the release the marker goes and the pawn drags again '
        '(quick 261110-cgd)', (tester) async {
      await pumpLayer(tester, character: characterLoaded(), prison: imprisoned);

      prisonStates.add(const PrisonState(null));
      await tester.pump();
      await tester.pump();

      expect(find.byKey(CharacterMarkerLayer.prisonLabelKey), findsNothing);
      expect(pawnDraggable(tester).maxSimultaneousDrags, isNull);
    });

    testWidgets('a free character shows no prison marker (quick 261110-cgd)', (
      tester,
    ) async {
      await pumpLayer(tester, character: characterLoaded());

      expect(find.byKey(CharacterMarkerLayer.prisonLabelKey), findsNothing);
    });
  });

  group('mission in progress (Phase 21)', () {
    testWidgets('a mission in progress blocks the drag (D-11, D-16)', (
      tester,
    ) async {
      await pumpLayer(
        tester,
        character: characterLoaded(missionInProgress: true),
      );

      expect(pawnDraggable(tester).maxSimultaneousDrags, 0);
      expect(pawnPoint(tester), home);
    });

    testWidgets('the guided flow shows «Missione in corso» over the pawn '
        '(D-16)', (tester) async {
      await pumpLayer(
        tester,
        character: characterLoaded(
          missionInProgress: true,
          guidedMissionInProgress: true,
        ),
      );

      expect(pawnDraggable(tester).maxSimultaneousDrags, 0);
      expect(
        find.descendant(
          of: find.byKey(CharacterMarkerLayer.missionLabelKey),
          matching: find.text('Missione in corso'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('a normal mission shows no «Missione in corso» (D-16)', (
      tester,
    ) async {
      await pumpLayer(
        tester,
        character: characterLoaded(
          missionInProgress: true,
          guidedMissionInProgress: false,
        ),
      );

      expect(find.byKey(CharacterMarkerLayer.missionLabelKey), findsNothing);
      expect(find.byKey(CharacterMarkerLayer.activityLabelKey), findsNothing);
      expect(pawnDraggable(tester).maxSimultaneousDrags, 0);
    });

    testWidgets('a hunt in progress reads «Cacciando…» over the pawn '
        '(UAT 2026-11-14)', (tester) async {
      await pumpLayer(
        tester,
        character: characterLoaded(
          pendingQuest: laneJson(questType: 'hunt'),
          missionInProgress: true,
          guidedMissionInProgress: false,
        ),
      );

      expect(
        tester
            .widget<PawnLabel>(
              find.byKey(CharacterMarkerLayer.activityLabelKey),
            )
            .text,
        'Cacciando…',
      );
      expect(find.byKey(CharacterMarkerLayer.missionLabelKey), findsNothing);
    });

    testWidgets('a hunt not started yet names no activity', (tester) async {
      await pumpLayer(
        tester,
        character: characterLoaded(
          pendingQuest: laneJson(questType: 'hunt'),
          missionInProgress: false,
        ),
      );

      expect(find.byKey(CharacterMarkerLayer.activityLabelKey), findsNothing);
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

    testWidgets('requoting holds the pawn on the destination (D-03)', (
      tester,
    ) async {
      await pumpLayer(
        tester,
        character: characterLoaded(),
        travel: TravelRequoting(
          destination: cityB,
          preview: preview,
          eta: null,
          previewedAt: null,
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

  group('pawn tap (D-24)', () {
    Future<void> tapPawn(WidgetTester tester) async {
      await tester.tap(find.byKey(CharacterMarkerLayer.pawnKey));
      // Un tap non raccolto passa alla mappa, che attende un eventuale doppio tap.
      await tester.pump(const Duration(seconds: 1));
    }

    testWidgets('a tap on the idle pawn opens the city it stands on (D-24)', (
      tester,
    ) async {
      await pumpLayer(tester, character: characterLoaded());

      await tapPawn(tester);

      expect(tapped, [cityA]);
      expect(dragEnds, isEmpty);
      expect(pawnPoint(tester), home);
    });

    testWidgets(
      'a tap on the pawn away from any city marker opens nothing (D-24)',
      (tester) async {
        await pumpLayer(
          tester,
          character: characterLoaded(locationId: 'poi-road-1'),
        );

        await tapPawn(tester);

        expect(tapped, isEmpty);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('a tap while a travel sheet is open opens nothing (D-24)', (
      tester,
    ) async {
      await pumpLayer(
        tester,
        character: characterLoaded(),
        travel: confirming(),
      );

      await tapPawn(tester);

      expect(tapped, isEmpty);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a tap on the travelling pawn opens nothing (D-24)', (
      tester,
    ) async {
      await pumpLayer(
        tester,
        character: characterLoaded(activeTravel: activeTravelJson()),
        progress: travelling(),
      );

      await tapPawn(tester);

      expect(tapped, isEmpty);
      expect(tester.takeException(), isNull);
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
