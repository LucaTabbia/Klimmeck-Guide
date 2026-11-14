import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/config/cloudinary_assets.dart';
import 'package:klimmeck_guide/shared/components/bookmark_ribbon.dart';
import 'package:klimmeck_guide/shared/components/popup/details_sheet_frame.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';

import '../../../helpers/landscape.dart';
import '../../../helpers/svg_cache_seed.dart';
import '../../../helpers/test_app.dart';

const _cardKey = ValueKey('frame-card');
const _bodyKey = ValueKey('frame-body');

Future<List<double>> _pump(
  WidgetTester tester, {
  bool? isMarked,
  bool isPending = false,
  VoidCallback? onToggle,
}) async {
  final cardSizes = <double>[];
  useLandscapePhone(tester);
  await tester.pumpWidget(
    buildTestApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: DetailsSheetFrame(
            cardBuilder: (size) {
              cardSizes.add(size);
              return SizedBox(key: _cardKey, height: size, width: size);
            },
            body: const Text('Dettagli', key: _bodyKey),
            isMarked: isMarked,
            isPending: isPending,
            onToggle: onToggle,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return cardSizes;
}

BookmarkRibbon _ribbon(WidgetTester tester) =>
    tester.widget<BookmarkRibbon>(find.byType(BookmarkRibbon));

void main() {
  setUp(
    () => seedSvgCache([
      CloudinaryAssets.emptySheet,
      CloudinaryAssets.bookmarkRed,
    ]),
  );

  testWidgets(
    'draws the card at half the inner width above a scrolling body (D-22)',
    (tester) async {
      final cardSizes = await _pump(tester);

      final screenHeight =
          tester.view.physicalSize.height / tester.view.devicePixelRatio;
      final svgWidth = screenHeight * 1.3 * (315 / 375);
      final innerWidth = svgWidth - 2 * (svgWidth / 9);
      expect(cardSizes.last, moreOrLessEquals(innerWidth / 2));
      expect(
        find.ancestor(
          of: find.byKey(_bodyKey),
          matching: find.byType(SingleChildScrollView),
        ),
        findsNWidgets(2),
      );
      expect(
        tester.getTopLeft(find.byKey(_cardKey)).dy,
        lessThan(tester.getTopLeft(find.byKey(_bodyKey)).dy),
      );
      expect(tester.takeException(), isNull);
    },
  );

  group('bookmark (D-22)', () {
    testWidgets('draws the bookmark only when isMarked is given (D-22)', (
      tester,
    ) async {
      await _pump(tester);
      expect(find.byType(BookmarkRibbon), findsNothing);

      await _pump(tester, isMarked: false);
      expect(find.byType(BookmarkRibbon), findsOneWidget);
      expect(_ribbon(tester).isMarked, isFalse);
      expect(_ribbon(tester).left, 20);

      await _pump(tester, isMarked: true);
      expect(find.byType(BookmarkRibbon), findsOneWidget);
      expect(_ribbon(tester).isMarked, isTrue);
    });

    testWidgets(
      'the bookmark tap calls onToggle and is faded while pending (D-22)',
      (tester) async {
        var taps = 0;
        await _pump(tester, isMarked: false, onToggle: () => taps++);
        expect(_ribbon(tester).opacity, 1);

        await tester.tap(
          find.descendant(
            of: find.byType(BookmarkRibbon),
            matching: find.byType(RotatedBox),
          ),
        );
        await tester.pump();
        expect(taps, 1);

        await _pump(tester, isMarked: false, isPending: true);
        expect(_ribbon(tester).opacity, KlimmeckGuideTheme.pendingInkOpacity);
      },
    );
  });
}
