import 'dart:math' as math;

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/config/cloudinary_assets.dart';
import 'package:klimmeck_guide/models/character/character.dart';
import 'package:klimmeck_guide/shared/components/cached_svg.dart';
import 'package:klimmeck_guide/screens/mainScreen/characterCubit/character_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/map/layers/pawn_pointer_layer.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/map/travelProgressCubit/travel_progress_cubit.dart';
import 'package:latlong2/latlong.dart';

import '../../../../../helpers/fixtures/travel_fixtures.dart';
import '../../../../../helpers/landscape.dart';
import '../../../../../helpers/map_harness.dart';
import '../../../../../helpers/mocks.dart';
import '../../../../../helpers/svg_cache_seed.dart';

void main() {
  late MockCharacterCubit characterCubit;
  late MockTravelProgressCubit progressCubit;

  setUp(() {
    characterCubit = MockCharacterCubit();
    progressCubit = MockTravelProgressCubit();
    seedSvgCache([CloudinaryAssets.arrowMap]);
  });

  Future<MapController> pumpLayer(WidgetTester tester) async {
    useLandscapePhone(tester);
    whenListen(
      characterCubit,
      const Stream<CharacterState>.empty(),
      initialState: CharacterLoaded(
        Character.fromJson(travellingCharacterJson()),
      ),
    );
    whenListen(
      progressCubit,
      const Stream<TravelProgressState>.empty(),
      initialState: const TravelProgressIdle(),
    );
    final controller = MapController();
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<CharacterCubit>.value(value: characterCubit),
          BlocProvider<TravelProgressCubit>.value(value: progressCubit),
        ],
        child: mapHarness(const [PawnPointerLayer()], controller: controller),
      ),
    );
    await tester.pump();
    return controller;
  }

  LatLng pawnPoint() =>
      Character.fromJson(travellingCharacterJson()).status!.location!.location!;

  testWidgets('no arrow while the pawn is on the screen', (tester) async {
    final controller = await pumpLayer(tester);

    controller.move(pawnPoint(), 2);
    await tester.pump();

    expect(find.byKey(PawnPointerLayer.arrowKey), findsNothing);
  });

  testWidgets('with the pawn off the screen an arrow near the edge turns '
      'towards it (UAT 2026-11-14)', (tester) async {
    final controller = await pumpLayer(tester);
    final pawn = pawnPoint();

    // la pedina resta molto a ovest del centro dello schermo
    controller.move(LatLng(pawn.latitude, pawn.longitude + 120), 5);
    await tester.pump();

    final arrow = find.byKey(PawnPointerLayer.arrowKey);
    expect(arrow, findsOneWidget);
    expect(
      tester
          .widget<CachedSvg>(
            find.descendant(of: arrow, matching: find.byType(CachedSvg)),
          )
          .url,
      CloudinaryAssets.url('v1794671761/arrowMap_ucuc2f.svg'),
    );
    final map = tester.getRect(find.byType(FlutterMap));
    final centre = tester.getCenter(arrow);
    expect(centre.dx - map.left, moreOrLessEquals(50, epsilon: 1));
    expect(
      tester.widget<Transform>(arrow).transform.getRotation().entry(1, 0),
      moreOrLessEquals(math.sin(math.pi / 2), epsilon: 1e-6),
    );
  });
}
