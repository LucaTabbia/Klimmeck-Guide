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
import 'package:klimmeck_guide/repository/services/time/server_clock_service.dart';
import 'package:klimmeck_guide/screens/mainScreen/characterCubit/character_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/questCubit/quest_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/map/components/travel_confirmation_sheet.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/map/cubit/world_map_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/map/layers/character_marker_layer.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/map/mapFocusCubit/map_focus_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/map/travelProgressCubit/arrival_reread_ledger.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/map/world_map.dart';
import 'package:klimmeck_guide/screens/mainScreen/travelCubit/travel_cubit.dart';
import 'package:latlong2/latlong.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/fakes/fake_server_clock_service.dart';
import '../../../../helpers/fixtures/travel_fixtures.dart';
import '../../../../helpers/landscape.dart';
import '../../../../helpers/mocks.dart';
import '../../../../helpers/svg_cache_seed.dart';
import '../../../../helpers/test_app.dart';

/// Città lontane: il rilascio della pedina sceglie l'una o l'altra senza ambiguità.
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
    marker: const [10.0, 120.0],
    image: null,
  ),
  'type': 'drusteaCapital',
});

/// Viaggio della fixture: 10:00 → 12:40 UTC.
final DateTime travelStart = DateTime.utc(2026, 10, 24, 10);
final DateTime travelEnd = DateTime.utc(2026, 10, 24, 12, 40);

late MockCharacterCubit characterCubit;
late MockQuestCubit questCubit;
late MockWorldMapCubit worldMapCubit;
late MockTravelCubit travelCubit;
late MapFocusCubit mapFocusCubit;
late StreamController<CharacterState> characterStates;
late StreamController<TravelState> travelStates;
late FakeServerClockService serverClock;
late ArrivalRereadLedger arrivalRereads;

CharacterLoaded characterLoaded({
  Map<String, dynamic>? activeTravel,
  String locationId = 'city-marker-1',
  List<double> location = departureWire,
}) => CharacterLoaded(
  Character.fromJson(
    travellingCharacterJson(
      activeTravel: activeTravel,
      locationId: locationId,
      location: location,
    ),
  ),
);

/// Monta la `WorldMap` reale con i cubit della shell mockati (07-10 la riusa).
Future<void> pumpWorldMap(
  WidgetTester tester, {
  required CharacterState character,
  TravelState travelState = const TravelIdle(),
  DateTime? serverNow,
}) async {
  useLandscapePhone(tester);
  serverClock = FakeServerClockService(serverNow ?? travelStart);
  whenListen(characterCubit, characterStates.stream, initialState: character);
  whenListen(travelCubit, travelStates.stream, initialState: travelState);
  whenListen(
    questCubit,
    const Stream<QuestState>.empty(),
    initialState: const QuestLoaded([]),
  );
  whenListen(
    worldMapCubit,
    const Stream<WorldMapState>.empty(),
    initialState: WorldMapInitial(),
  );
  await tester.pumpWidget(
    buildTestApp(
      home: MultiRepositoryProvider(
        providers: [
          RepositoryProvider<ServerClockService>.value(value: serverClock),
          RepositoryProvider<ArrivalRereadLedger>.value(value: arrivalRereads),
        ],
        child: MultiBlocProvider(
          providers: [
            BlocProvider<CharacterCubit>.value(value: characterCubit),
            BlocProvider<QuestCubit>.value(value: questCubit),
            BlocProvider<WorldMapCubit>.value(value: worldMapCubit),
            BlocProvider<TravelCubit>.value(value: travelCubit),
            BlocProvider<MapFocusCubit>.value(value: mapFocusCubit),
          ],
          child: Scaffold(body: WorldMap(cities: [cityA, cityB])),
        ),
      ),
    ),
  );
  await tester.pump();
}

MapCamera mapCamera(WidgetTester tester) =>
    tester.widget<FlutterMap>(find.byType(FlutterMap)).mapController!.camera;

void expectCentreAt(WidgetTester tester, LatLng expected) {
  final centre = mapCamera(tester).center;
  expect(centre.latitude, closeTo(expected.latitude, 1e-6));
  expect(centre.longitude, closeTo(expected.longitude, 1e-6));
}

/// Posizione interpolata della pedina all'ora server [now] (stesso modello del cubit).
LatLng pawnAt(DateTime now) {
  final travel = ActiveTravel.fromJson(activeTravelJson());
  final progress = travelProgress(
    serverNow: now,
    startTime: travel.startTime,
    durationMs: travel.duration,
  );
  return TravelRoute.of(travel.road.points).pointAt(progress)!;
}

List<Polyline> routePolylines(WidgetTester tester) =>
    tester.widget<PolylineLayer>(find.byType(PolylineLayer)).polylines;

/// Il cubit mockato passa a `TravelPreviewing`: il foglio resta aperto (guardia 07-08).
void previewKeepsTheSheetOpen() {
  when(
    () => travelCubit.preview(
      characterId: any(named: 'characterId'),
      destination: any(named: 'destination'),
    ),
  ).thenAnswer((invocation) async {
    final destination = invocation.namedArguments[#destination] as City;
    travelStates.add(TravelPreviewing(destination));
  });
}

Future<void> dragPawnBy(WidgetTester tester, Offset offset) async {
  await tester.drag(find.byType(Draggable), offset);
  await tester.pumpAndSettle();
}

/// Il foglio apre a metà schermo (PaperSheetModal): si trascina dalla pergamena visibile.
Future<void> dragSheetDown(WidgetTester tester) async {
  await tester.dragFrom(const Offset(390, 250), const Offset(0, 300));
  await tester.pumpAndSettle();
}

TravelConfirming confirmingAlong(List<List<double>> coordinates) =>
    TravelConfirming(
      destination: cityB,
      preview: TravelPreview.fromJson(
        travelPreviewJson(road: travelPathJson(coordinates: coordinates)),
      ),
      eta: travelEnd,
      previewedAt: travelStart,
    );

void main() {
  setUpAll(() => registerFallbackValue(cityA));

  setUp(() {
    characterCubit = MockCharacterCubit();
    questCubit = MockQuestCubit();
    worldMapCubit = MockWorldMapCubit();
    travelCubit = MockTravelCubit();
    mapFocusCubit = MapFocusCubit();
    arrivalRereads = ArrivalRereadLedger();
    characterStates = StreamController<CharacterState>.broadcast();
    travelStates = StreamController<TravelState>.broadcast();
    when(() => characterCubit.refreshCharacter()).thenAnswer((_) async {});
    when(
      () => travelCubit.preview(
        characterId: any(named: 'characterId'),
        destination: any(named: 'destination'),
      ),
    ).thenAnswer((_) async {});
    when(() => travelCubit.cancel()).thenReturn(null);
    seedSvgCache([
      CloudinaryAssets.cliffbreak,
      CloudinaryAssets.adventurerMalePawn,
      CloudinaryAssets.bottomEmptySheet,
    ]);
  });

  tearDown(() async {
    await characterStates.close();
    await travelStates.close();
    await mapFocusCubit.close();
  });

  final midTravel = travelStart.add(const Duration(minutes: 80));

  group('travel progress on the map', () {
    testWidgets('without a travel draws no route and keeps the camera', (
      tester,
    ) async {
      await pumpWorldMap(tester, character: characterLoaded());

      expect(find.byType(PolylineLayer), findsNothing);
      expectCentreAt(tester, const LatLng(0, 0));
    });

    testWidgets('frames the travelling pawn on map ready', (tester) async {
      await pumpWorldMap(
        tester,
        character: characterLoaded(activeTravel: activeTravelJson()),
        serverNow: midTravel,
      );

      expect(routePolylines(tester), hasLength(2));
      expectCentreAt(tester, pawnAt(midTravel));
    });

    testWidgets('frames the pawn once and never follows it', (tester) async {
      await pumpWorldMap(
        tester,
        character: characterLoaded(activeTravel: activeTravelJson()),
        serverNow: midTravel,
      );
      final travelledBefore = routePolylines(tester).first.points;

      serverClock.advance(const Duration(minutes: 40));
      await tester.pump(const Duration(seconds: 1));

      expect(routePolylines(tester).first.points, isNot(travelledBefore));
      expectCentreAt(tester, pawnAt(midTravel));
    });

    testWidgets('removes the route when the backend clears the travel', (
      tester,
    ) async {
      await pumpWorldMap(
        tester,
        character: characterLoaded(activeTravel: activeTravelJson()),
        serverNow: midTravel,
      );
      expect(find.byType(PolylineLayer), findsOneWidget);

      characterStates.add(
        characterLoaded(locationId: 'city-marker-2', location: destinationWire),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byType(PolylineLayer), findsNothing);
    });

    testWidgets('unmounting the map leaves no pending timer', (tester) async {
      await pumpWorldMap(
        tester,
        character: characterLoaded(activeTravel: activeTravelJson()),
        serverNow: midTravel,
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 2));

      expect(find.byType(FlutterMap), findsNothing);
    });
  });

  group('reconstruction after a kill (TRAVEL-04)', () {
    testWidgets('after a kill a fresh map resumes the pawn mid road', (
      tester,
    ) async {
      await pumpWorldMap(
        tester,
        character: characterLoaded(activeTravel: activeTravelJson()),
        serverNow: midTravel,
      );

      final pawn = tester
          .widget<MarkerLayer>(
            find.ancestor(
              of: find.byKey(CharacterMarkerLayer.pawnKey),
              matching: find.byType(MarkerLayer),
            ),
          )
          .markers
          .first
          .point;
      final expected = TravelRoute.of(
        ActiveTravel.fromJson(activeTravelJson()).road.points,
      ).pointAt(0.5)!;
      expect(pawn.latitude, closeTo(expected.latitude, 1e-6));
      expect(pawn.longitude, closeTo(expected.longitude, 1e-6));
      expect(
        find.descendant(
          of: find.byKey(CharacterMarkerLayer.travelLabelKey),
          matching: find.text('1 h 20 min'),
        ),
        findsOneWidget,
      );
    });
  });

  group('travelEnd focus (D-15)', () {
    testWidgets('a focus requested before mount centres the pawn on ready', (
      tester,
    ) async {
      mapFocusCubit.requestCharacterFocus();

      await pumpWorldMap(tester, character: characterLoaded());

      expectCentreAt(tester, const LatLng(10, 20));
      expect(mapFocusCubit.state.isCharacterFocusPending, isFalse);
    });

    testWidgets('a focus requested while mounted moves to the pawn', (
      tester,
    ) async {
      await pumpWorldMap(
        tester,
        character: characterLoaded(activeTravel: activeTravelJson()),
        serverNow: midTravel,
      );
      tester
          .widget<FlutterMap>(find.byType(FlutterMap))
          .mapController!
          .move(const LatLng(0, 0), 2);
      await tester.pump();

      mapFocusCubit.requestCharacterFocus();
      await tester.pump();

      expectCentreAt(tester, pawnAt(midTravel));
      expect(mapFocusCubit.state.isCharacterFocusPending, isFalse);
    });
  });

  group('silent arrival rereads (D-10)', () {
    testWidgets('rereads the character at most twice after endTime', (
      tester,
    ) async {
      await pumpWorldMap(
        tester,
        character: characterLoaded(activeTravel: activeTravelJson()),
        serverNow: travelEnd.add(const Duration(seconds: 6)),
      );
      verify(() => characterCubit.refreshCharacter()).called(1);

      serverClock.advance(const Duration(seconds: 60));
      await tester.pump(const Duration(seconds: 1));
      verify(() => characterCubit.refreshCharacter()).called(1);

      serverClock.advance(const Duration(minutes: 5));
      await tester.pump(const Duration(seconds: 2));
      verifyNever(() => characterCubit.refreshCharacter());
    });
  });

  group('reread cap across remounts (WR-02)', () {
    testWidgets('returning to the map in the arriving window adds no reread', (
      tester,
    ) async {
      await pumpWorldMap(
        tester,
        character: characterLoaded(activeTravel: activeTravelJson()),
        serverNow: travelEnd.add(const Duration(seconds: 6)),
      );
      verify(() => characterCubit.refreshCharacter()).called(1);

      await tester.pumpWidget(const SizedBox.shrink());
      await pumpWorldMap(
        tester,
        character: characterLoaded(activeTravel: activeTravelJson()),
        serverNow: travelEnd.add(const Duration(seconds: 7)),
      );

      verifyNever(() => characterCubit.refreshCharacter());
    });

    testWidgets('a backward resync does not reread the same threshold', (
      tester,
    ) async {
      await pumpWorldMap(
        tester,
        character: characterLoaded(activeTravel: activeTravelJson()),
        serverNow: travelEnd.add(const Duration(seconds: 6)),
      );
      verify(() => characterCubit.refreshCharacter()).called(1);

      serverClock.resync(travelEnd.subtract(const Duration(seconds: 10)));
      await tester.pump();
      serverClock.advance(const Duration(seconds: 16));
      await tester.pump(const Duration(seconds: 1));

      verifyNever(() => characterCubit.refreshCharacter());
    });
  });

  group('drag to travel (D-01..D-04)', () {
    testWidgets('releasing on another city previews it and opens the sheet', (
      tester,
    ) async {
      previewKeepsTheSheetOpen();
      await pumpWorldMap(tester, character: characterLoaded());

      await dragPawnBy(tester, const Offset(300, 0));

      verify(
        () => travelCubit.preview(characterId: 'c-1', destination: cityB),
      ).called(1);
      final sheet = tester.widget<TravelConfirmationSheet>(
        find.byType(TravelConfirmationSheet),
      );
      expect(sheet.destination, cityB);
      final route = ModalRoute.of(
        tester.element(find.byType(TravelConfirmationSheet)),
      )!;
      expect(route.barrierColor, Colors.transparent);
    });

    testWidgets('releasing on the current city does nothing', (tester) async {
      previewKeepsTheSheetOpen();
      await pumpWorldMap(tester, character: characterLoaded());

      await dragPawnBy(tester, const Offset(40, 0));

      verifyNever(
        () => travelCubit.preview(
          characterId: any(named: 'characterId'),
          destination: any(named: 'destination'),
        ),
      );
      expect(find.byType(TravelConfirmationSheet), findsNothing);
    });

    testWidgets('dismissing the sheet cancels the travel flow', (tester) async {
      previewKeepsTheSheetOpen();
      await pumpWorldMap(tester, character: characterLoaded());
      await dragPawnBy(tester, const Offset(300, 0));
      expect(find.byType(TravelConfirmationSheet), findsOneWidget);

      // PaperSheetModal occupa tutta l'altezza: la barriera non riceve tap.
      Navigator.of(tester.element(find.byType(TravelConfirmationSheet))).pop();
      await tester.pumpAndSettle();

      expect(find.byType(TravelConfirmationSheet), findsNothing);
      verify(() => travelCubit.cancel()).called(1);
    });

    testWidgets('dragging the sheet down cannot dismiss a start in flight', (
      tester,
    ) async {
      previewKeepsTheSheetOpen();
      await pumpWorldMap(tester, character: characterLoaded());
      await dragPawnBy(tester, const Offset(300, 0));
      travelStates.add(
        TravelStarting(
          destination: cityB,
          preview: TravelPreview.fromJson(travelPreviewJson()),
          eta: travelEnd,
          previewedAt: travelStart,
        ),
      );
      await tester.pump();

      await dragSheetDown(tester);

      expect(find.byType(TravelConfirmationSheet), findsOneWidget);
    });

    testWidgets('dragging the sheet down dismisses it before the start', (
      tester,
    ) async {
      previewKeepsTheSheetOpen();
      await pumpWorldMap(tester, character: characterLoaded());
      await dragPawnBy(tester, const Offset(300, 0));

      await dragSheetDown(tester);

      expect(find.byType(TravelConfirmationSheet), findsNothing);
    });

    testWidgets('a preview rejected before the first frame leaves no sheet', (
      tester,
    ) async {
      await pumpWorldMap(tester, character: characterLoaded());

      await dragPawnBy(tester, const Offset(300, 0));

      expect(find.byType(TravelConfirmationSheet), findsNothing);
      verify(() => travelCubit.cancel()).called(1);
    });

    testWidgets('fits the camera on the previewed route', (tester) async {
      await pumpWorldMap(tester, character: characterLoaded());

      travelStates.add(
        confirmingAlong(const [
          departureWire,
          [10.0, 70.0],
          [10.0, 120.0],
        ]),
      );
      await tester.pump();
      await tester.pump();

      final bounds = mapCamera(tester).visibleBounds;
      expect(bounds.contains(const LatLng(10, 20)), isTrue);
      expect(bounds.contains(const LatLng(10, 120)), isTrue);
    });

    testWidgets('a route with fewer than two points leaves the camera', (
      tester,
    ) async {
      await pumpWorldMap(tester, character: characterLoaded());

      travelStates.add(confirmingAlong(const [departureWire]));
      await tester.pump();
      await tester.pump();

      expect(tester.takeException(), isNull);
      expectCentreAt(tester, const LatLng(0, 0));
    });
  });
}
