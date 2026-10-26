import 'dart:async';
import 'dart:io';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/config/cloudinary_assets.dart';
import 'package:klimmeck_guide/models/city.dart';
import 'package:klimmeck_guide/models/travel/travel_preview.dart';
import 'package:klimmeck_guide/models/travel/travel_time_format.dart';
import 'package:klimmeck_guide/repository/cache/svg_cache.dart';
import 'package:klimmeck_guide/repository/travel_failure.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/map/components/travel_confirmation_sheet.dart';
import 'package:klimmeck_guide/screens/mainScreen/travelCubit/travel_cubit.dart';
import 'package:klimmeck_guide/shared/components/cached_svg.dart';
import 'package:klimmeck_guide/shared/components/modal/paper_sheet_modal.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/fixtures/travel_fixtures.dart';
import '../../../../helpers/landscape.dart';
import '../../../../helpers/mocks.dart';
import '../../../../helpers/test_app.dart';

void main() {
  const loreImage = 'https://res.cloudinary.com/demo/valdoria.svg';
  const openSheetKey = ValueKey('test.openSheet');
  final valdoria = City.fromJson(travelCityJson(image: null));
  final valdoriaWithImage = City.fromJson(travelCityJson());
  final preview = TravelPreview.fromJson(travelPreviewJson());
  final previewedAt = DateTime.utc(2026, 10, 24, 10);
  final eta = DateTime.utc(2026, 10, 24, 12, 40);

  late MockTravelCubit cubit;
  late StreamController<TravelState> states;

  setUp(() {
    cubit = MockTravelCubit();
    states = StreamController<TravelState>.broadcast();
    when(() => cubit.start()).thenAnswer((_) async {});
    when(() => cubit.cancel()).thenReturn(null);
    final svg =
        File('${Directory.systemTemp.createTempSync('kg_svg').path}/seed.svg')
          ..writeAsStringSync(
            '<svg xmlns="http://www.w3.org/2000/svg" width="1" height="1"/>',
          );
    SvgCache().add(loreImage, svg);
    SvgCache().add(
      CloudinaryAssets.url(CloudinaryAssets.bottomEmptySheet),
      svg,
    );
  });

  tearDown(() => states.close());

  TravelConfirming confirming({City? destination}) => TravelConfirming(
    destination: destination ?? valdoria,
    preview: preview,
    eta: eta,
    previewedAt: previewedAt,
  );

  TravelStarting starting() => TravelStarting(
    destination: valdoria,
    preview: preview,
    eta: eta,
    previewedAt: previewedAt,
  );

  void seed(TravelState initial) =>
      whenListen(cubit, states.stream, initialState: initial);

  Future<void> pumpSheet(
    WidgetTester tester,
    TravelState initial, {
    City? destination,
  }) async {
    useLandscapePhone(tester);
    seed(initial);
    await tester.pumpWidget(
      buildTestApp(
        home: BlocProvider<TravelCubit>.value(
          value: cubit,
          child: Scaffold(
            body: SingleChildScrollView(
              child: TravelConfirmationSheet(
                destination: destination ?? valdoria,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> openSheet(WidgetTester tester, TravelState initial) async {
    useLandscapePhone(tester);
    seed(initial);
    await tester.pumpWidget(
      buildTestApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              key: openSheetKey,
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => BlocProvider<TravelCubit>.value(
                  value: cubit,
                  child: PaperSheetModal(
                    child: TravelConfirmationSheet(destination: valdoria),
                  ),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(openSheetKey));
    await tester.pumpAndSettle();
  }

  TextButton departButton(WidgetTester tester) =>
      tester.widget<TextButton>(find.byKey(TravelConfirmationSheet.departKey));

  TextButton stayButton(WidgetTester tester) =>
      tester.widget<TextButton>(find.byKey(TravelConfirmationSheet.stayKey));

  testWidgets('shows the destination at once with subtle placeholders', (
    tester,
  ) async {
    await pumpSheet(tester, TravelPreviewing(valdoria));

    expect(find.text('Valdoria'), findsOneWidget);
    expect(find.text(TravelConfirmationSheet.pendingValue), findsNWidgets(3));
    expect(departButton(tester).onPressed, isNull);
    expect(stayButton(tester).onPressed, isNotNull);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('shows the backend distance, duration and arrival', (
    tester,
  ) async {
    await pumpSheet(tester, confirming());

    expect(find.text('Distanza'), findsOneWidget);
    expect(find.text('Durata'), findsOneWidget);
    expect(find.text('Arrivo'), findsOneWidget);
    expect(find.text('15,8 km'), findsOneWidget);
    expect(find.text('2 h 40 min'), findsOneWidget);
    expect(
      find.text(formatArrival(eta, serverNow: previewedAt)),
      findsOneWidget,
    );
    expect(find.text(TravelConfirmationSheet.pendingValue), findsNothing);
  });

  testWidgets('keeps only the arrival pending on an unsynced clock', (
    tester,
  ) async {
    await pumpSheet(
      tester,
      TravelConfirming(
        destination: valdoria,
        preview: preview,
        eta: null,
        previewedAt: null,
      ),
    );

    expect(find.text('15,8 km'), findsOneWidget);
    expect(find.text('2 h 40 min'), findsOneWidget);
    expect(find.text(TravelConfirmationSheet.pendingValue), findsOneWidget);
    expect(departButton(tester).onPressed, isNotNull);
  });

  testWidgets('tapping Parti starts the travel exactly once', (tester) async {
    await pumpSheet(tester, confirming());

    await tester.tap(find.byKey(TravelConfirmationSheet.departKey));
    await tester.pump();

    verify(() => cubit.start()).called(1);
  });

  testWidgets('keeps the numbers and disables Parti while starting', (
    tester,
  ) async {
    await pumpSheet(tester, starting());

    expect(find.text('15,8 km'), findsOneWidget);
    expect(departButton(tester).onPressed, isNull);
  });

  testWidgets('disables Resta while the start is in flight', (tester) async {
    await pumpSheet(tester, starting());

    expect(stayButton(tester).onPressed, isNull);
  });

  testWidgets('back and barrier cannot dismiss a start in flight', (
    tester,
  ) async {
    await openSheet(tester, starting());

    final navigator = Navigator.of(
      tester.element(find.byType(TravelConfirmationSheet)),
    );
    await navigator.maybePop();
    await tester.pumpAndSettle();

    expect(find.byType(TravelConfirmationSheet), findsOneWidget);
    verifyNever(() => cubit.cancel());
  });

  testWidgets('a start rejection still closes the blocked sheet', (
    tester,
  ) async {
    await openSheet(tester, starting());

    states.add(
      TravelFailed(
        destination: valdoria,
        failure: TravelFailure.noPath,
        stage: TravelStage.start,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(TravelConfirmationSheet), findsNothing);
  });

  testWidgets('renders the lore image when the destination has one', (
    tester,
  ) async {
    await pumpSheet(
      tester,
      confirming(destination: valdoriaWithImage),
      destination: valdoriaWithImage,
    );

    final image = tester.widget<CachedSvg>(find.byType(CachedSvg));
    expect(image.url, loreImage);
  });

  testWidgets('omits the image when the lore has none', (tester) async {
    await pumpSheet(tester, confirming());

    expect(find.byType(CachedSvg), findsNothing);
  });

  testWidgets('tapping Resta cancels and closes the sheet', (tester) async {
    await openSheet(tester, confirming());
    expect(find.byType(TravelConfirmationSheet), findsOneWidget);

    stayButton(tester).onPressed!();
    await tester.pumpAndSettle();

    verify(() => cubit.cancel()).called(1);
    expect(find.byType(TravelConfirmationSheet), findsNothing);
  });

  testWidgets('closes itself when the travel starts', (tester) async {
    await openSheet(tester, starting());

    states.add(TravelStarted(destination: valdoria, preview: preview));
    await tester.pumpAndSettle();

    expect(find.byType(TravelConfirmationSheet), findsNothing);
  });

  testWidgets('closes itself on a rejection', (tester) async {
    await openSheet(tester, TravelPreviewing(valdoria));

    states.add(
      TravelFailed(
        destination: valdoria,
        failure: TravelFailure.noPath,
        stage: TravelStage.preview,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(TravelConfirmationSheet), findsNothing);
  });

  testWidgets('closes itself when the flow is already idle at mount', (
    tester,
  ) async {
    await openSheet(tester, const TravelIdle());

    expect(find.byType(TravelConfirmationSheet), findsNothing);
  });

  testWidgets('closes itself when the preview already failed at mount', (
    tester,
  ) async {
    await openSheet(
      tester,
      TravelFailed(
        destination: valdoria,
        failure: TravelFailure.sameLocation,
        stage: TravelStage.preview,
      ),
    );

    expect(find.byType(TravelConfirmationSheet), findsNothing);
  });

  testWidgets('stays open when it is already previewing at mount', (
    tester,
  ) async {
    await openSheet(tester, TravelPreviewing(valdoria));

    expect(find.byType(TravelConfirmationSheet), findsOneWidget);
  });

  testWidgets('uses no app chrome and accessible actions', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpSheet(tester, confirming());

    expect(find.byType(AlertDialog), findsNothing);
    expect(find.byType(AppBar), findsNothing);
    expect(find.byType(SnackBar), findsNothing);
    for (final key in [
      TravelConfirmationSheet.departKey,
      TravelConfirmationSheet.stayKey,
    ]) {
      final size = tester.getSize(find.byKey(key));
      expect(size.width, greaterThanOrEqualTo(44));
      expect(size.height, greaterThanOrEqualTo(44));
    }
    expect(find.bySemanticsLabel(RegExp('Parti')), findsWidgets);
    expect(find.bySemanticsLabel(RegExp('Resta')), findsWidgets);
    semantics.dispose();
  });
}
