import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/city.dart';
import 'package:klimmeck_guide/models/travel/active_travel.dart';
import 'package:klimmeck_guide/models/travel/travel_preview.dart';
import 'package:klimmeck_guide/models/travel/travel_route.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/map/layers/travel_route_layer.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/map/travelProgressCubit/travel_progress_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/travelCubit/travel_cubit.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';
import 'package:latlong2/latlong.dart';

import '../../../../helpers/fixtures/travel_fixtures.dart';
import '../../../../helpers/landscape.dart';
import '../../../../helpers/map_harness.dart';
import '../../../../helpers/mocks.dart';

void main() {
  const a = LatLng(10, 20);
  const b = LatLng(11, 21);
  const c = LatLng(12, 23);
  final valdoria = City.fromJson(travelCityJson(image: null));
  final preview = TravelPreview.fromJson(travelPreviewJson());
  final eta = DateTime.utc(2026, 10, 24, 12, 40);
  final previewedAt = DateTime.utc(2026, 10, 24, 10);

  late MockTravelProgressCubit progressCubit;
  late MockTravelCubit travelCubit;

  setUp(() {
    progressCubit = MockTravelProgressCubit();
    travelCubit = MockTravelCubit();
  });

  TravelProgressActive activeProgress({
    required List<LatLng> travelled,
    required List<LatLng> remaining,
    List<LatLng> route = const [a, b, c],
  }) => TravelProgressActive(
    travel: ActiveTravel.fromJson(activeTravelJson()),
    route: TravelRoute.of(route),
    position: route.isEmpty ? null : travelled.last,
    travelled: travelled,
    remaining: remaining,
    remainingTime: const Duration(hours: 1),
    isArriving: false,
    arrivalRefetchCount: 0,
  );

  TravelConfirming confirming() => TravelConfirming(
    destination: valdoria,
    preview: preview,
    eta: eta,
    previewedAt: previewedAt,
  );

  Future<void> pumpLayer(
    WidgetTester tester, {
    TravelProgressState progress = const TravelProgressIdle(),
    TravelState travel = const TravelIdle(),
  }) async {
    useLandscapePhone(tester);
    whenListen(
      progressCubit,
      const Stream<TravelProgressState>.empty(),
      initialState: progress,
    );
    whenListen(
      travelCubit,
      const Stream<TravelState>.empty(),
      initialState: travel,
    );
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<TravelProgressCubit>.value(value: progressCubit),
          BlocProvider<TravelCubit>.value(value: travelCubit),
        ],
        child: mapHarness(const [TravelRouteLayer()]),
      ),
    );
    await tester.pump();
  }

  List<Polyline> renderedPolylines(WidgetTester tester) =>
      tester.widget<PolylineLayer>(find.byType(PolylineLayer)).polylines;

  bool isDashed(Polyline polyline) =>
      polyline.pattern.segments != null &&
      polyline.pattern.spacingFactor == null;

  group('TravelRouteLayer', () {
    testWidgets('draws nothing when idle', (tester) async {
      await pumpLayer(tester);

      expect(find.byType(PolylineLayer), findsNothing);
    });

    testWidgets('draws the preview road as one dashed polyline', (
      tester,
    ) async {
      await pumpLayer(tester, travel: confirming());

      final polylines = renderedPolylines(tester);
      expect(polylines, hasLength(1));
      expect(polylines.single.points, preview.road.points);
      expect(isDashed(polylines.single), isTrue);
    });

    testWidgets('keeps the dashed preview while starting', (tester) async {
      await pumpLayer(
        tester,
        travel: TravelStarting(
          destination: valdoria,
          preview: preview,
          eta: eta,
          previewedAt: previewedAt,
        ),
      );

      final polylines = renderedPolylines(tester);
      expect(polylines, hasLength(1));
      expect(polylines.single.points, preview.road.points);
      expect(isDashed(polylines.single), isTrue);
    });

    testWidgets('keeps the dashed preview until activeTravel arrives', (
      tester,
    ) async {
      await pumpLayer(
        tester,
        travel: TravelStarted(destination: valdoria, preview: preview),
      );

      final polylines = renderedPolylines(tester);
      expect(polylines, hasLength(1));
      expect(polylines.single.points, preview.road.points);
      expect(isDashed(polylines.single), isTrue);
    });

    testWidgets('draws the live route in two tones over a started preview', (
      tester,
    ) async {
      await pumpLayer(
        tester,
        progress: activeProgress(
          travelled: const [a, b],
          remaining: const [b, c, c],
        ),
        travel: TravelStarted(destination: valdoria, preview: preview),
      );

      final polylines = renderedPolylines(tester);
      expect(polylines, hasLength(2));
      final travelled = polylines.first;
      final remaining = polylines.last;
      expect(travelled.points, const [a, b]);
      expect(travelled.pattern, const StrokePattern.solid());
      expect(travelled.color, KlimmeckGuideTheme.royalCrimson);
      expect(remaining.points, const [b, c, c]);
      expect(isDashed(remaining), isTrue);
      expect(remaining.color, KlimmeckGuideTheme.darkWood);
    });

    testWidgets('skips a travelled part with fewer than two points', (
      tester,
    ) async {
      await pumpLayer(
        tester,
        progress: activeProgress(
          travelled: const [a],
          remaining: const [a, b, c],
        ),
      );

      final polylines = renderedPolylines(tester);
      expect(polylines, hasLength(1));
      expect(polylines.single.points, const [a, b, c]);
      expect(isDashed(polylines.single), isTrue);
    });

    testWidgets('draws nothing for an empty route', (tester) async {
      await pumpLayer(
        tester,
        progress: activeProgress(
          travelled: const [],
          remaining: const [],
          route: const [],
        ),
      );

      expect(find.byType(PolylineLayer), findsNothing);
    });
  });

  group('travelRoutePolylines', () {
    test('returns no polyline when idle', () {
      expect(
        travelRoutePolylines(
          progress: const TravelProgressIdle(),
          travel: const TravelIdle(),
        ),
        isEmpty,
      );
    });

    test('returns no polyline while the preview is in flight', () {
      expect(
        travelRoutePolylines(
          progress: const TravelProgressIdle(),
          travel: TravelPreviewing(valdoria),
        ),
        isEmpty,
      );
    });

    test('returns the dashed preview while confirming', () {
      final polylines = travelRoutePolylines(
        progress: const TravelProgressIdle(),
        travel: confirming(),
      );

      expect(polylines, hasLength(1));
      expect(polylines.single.points, preview.road.points);
      expect(isDashed(polylines.single), isTrue);
      expect(polylines.single.color, KlimmeckGuideTheme.darkWood);
    });

    test('lets the live route win over the preview', () {
      final polylines = travelRoutePolylines(
        progress: activeProgress(
          travelled: const [a, b],
          remaining: const [b, c],
        ),
        travel: confirming(),
      );

      expect(polylines.map((p) => p.points), [
        const [a, b],
        const [b, c],
      ]);
    });

    test('skips a preview road with fewer than two points', () {
      final degenerate = TravelPreview.fromJson(
        travelPreviewJson(
          road: travelPathJson(coordinates: const [departureWire]),
        ),
      );

      expect(
        travelRoutePolylines(
          progress: const TravelProgressIdle(),
          travel: TravelStarted(destination: valdoria, preview: degenerate),
        ),
        isEmpty,
      );
    });
  });
}
