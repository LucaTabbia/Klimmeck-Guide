import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/config/cloudinary_assets.dart';
import 'package:klimmeck_guide/models/quest_result/quest_result.dart';
import 'package:klimmeck_guide/shared/components/cached_svg.dart';
import 'package:klimmeck_guide/shared/components/popup/ambush_report_carousel.dart';
import 'package:klimmeck_guide/shared/components/popup/quest_result_sheet.dart';

import '../../../helpers/fixtures/quest_result_fixtures.dart';
import '../../../helpers/landscape.dart';
import '../../../helpers/svg_cache_seed.dart';
import '../../../helpers/test_app.dart';

final QuestResult _won = questResult(ambushWonResultJson());
final QuestResult _lost = questResult(ambushLostResultJson());

/// D-19: with several reports each page slot takes this fraction of the
/// viewport, so the neighbour parchment (centred in its slot) peeks in.
const double _peekViewportFraction = 0.62;
const double _peekEdge = (1 - _peekViewportFraction) / 2;

/// Least visible strip of the neighbour parchment, as a fraction of the width.
const double _minVisiblePeek = 0.05;

/// D-19: the opening nudge rests this long after the route transition, then
/// carries the pages by at most this fraction of the carousel width.
const Duration _nudgeDelay = Duration(milliseconds: 200);
const double _nudgeFraction = 0.06;

/// Fade of the presenter's `showGeneralDialog` that hosts the carousel.
const Duration _routeTransition = Duration(milliseconds: 250);

/// Pumps the carousel and one more frame only: the opening nudge is live.
Future<void> _pumpUnsettled(
  WidgetTester tester,
  List<QuestResult> results, {
  VoidCallback? onContinue,
}) async {
  useLandscapePhone(tester);
  await tester.pumpWidget(
    buildTestApp(
      home: Scaffold(
        body: AmbushReportCarousel(
          results: results,
          onContinue: onContinue ?? () {},
        ),
      ),
    ),
  );
  await tester.pump();
}

/// Hosts the carousel in a dialog route like the presenter does (fade of
/// `_routeTransition`) and taps it open: one frame pumped, the fade is live.
Future<void> _pumpInDialog(
  WidgetTester tester,
  List<QuestResult> results,
) async {
  useLandscapePhone(tester);
  await tester.pumpWidget(
    buildTestApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => showGeneralDialog<void>(
              context: context,
              transitionDuration: _routeTransition,
              pageBuilder: (_, __, ___) => Material(
                type: MaterialType.transparency,
                child: AmbushReportCarousel(
                  results: results,
                  onContinue: () {},
                ),
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('open'));
  await tester.pump();
}

Future<void> _pump(
  WidgetTester tester,
  List<QuestResult> results, {
  VoidCallback? onContinue,
}) async {
  await _pumpUnsettled(tester, results, onContinue: onContinue);
  await tester.pumpAndSettle();
}

Future<void> _swipe(WidgetTester tester, double dx) async {
  await tester.fling(
    find.byKey(AmbushReportCarousel.pagesKey),
    Offset(dx, 0),
    1000,
  );
  await tester.pumpAndSettle();
}

Finder _page(QuestResult result) =>
    find.byKey(ValueKey('ambushReportCarousel.page.${result.id}'));

/// The parchment background of a page: the first SVG the sheet paints.
Finder _parchmentOf(QuestResult result) =>
    find.descendant(of: _page(result), matching: find.byType(CachedSvg)).first;

Finder _continueOf(QuestResult result) => find.descendant(
  of: _page(result),
  matching: find.byKey(QuestResultSheet.continueKey),
);

double _viewportWidth(WidgetTester tester) =>
    tester.getSize(find.byKey(AmbushReportCarousel.pagesKey)).width;

void main() {
  setUp(
    () => seedSvgCache([
      CloudinaryAssets.emptySheet,
      CloudinaryAssets.emptyCardSheet,
      CloudinaryAssets.healEffect,
      CloudinaryAssets.helmetType,
      CloudinaryAssets.goldCoin,
      CloudinaryAssets.silverCoin,
      CloudinaryAssets.copperCoin,
    ]),
  );

  group('AmbushReportCarousel (D-05)', () {
    testWidgets('opens on the first report with the «1 di N» counter (D-05)', (
      tester,
    ) async {
      await _pump(tester, [_won, _lost]);

      expect(find.text('Vittoria'), findsOneWidget);
      expect(find.text('1 di 2'), findsOneWidget);
      expect(find.text('Sconfitta').hitTestable(), findsNothing);
    });

    testWidgets('a swipe shows the next report with its counter (D-05)', (
      tester,
    ) async {
      await _pump(tester, [_won, _lost]);

      await _swipe(tester, -600);

      expect(find.text('2 di 2'), findsOneWidget);
      expect(find.text('Portato a Bosa'), findsOneWidget);
    });

    testWidgets('a swipe back returns to the previous report (D-05)', (
      tester,
    ) async {
      await _pump(tester, [_won, _lost]);

      await _swipe(tester, -600);
      await _swipe(tester, 600);

      expect(find.text('1 di 2'), findsOneWidget);
    });

    testWidgets('a single ambush shows no page counter (D-05)', (tester) async {
      await _pump(tester, [_won]);

      expect(find.byKey(QuestResultSheet.counterKey), findsNothing);
    });

    testWidgets('Continua on page 1 closes and acks all (D-05)', (
      tester,
    ) async {
      var closes = 0;
      await _pump(tester, [_won, _lost], onContinue: () => closes++);

      await tester.tap(_continueOf(_won));
      await tester.pumpAndSettle();

      expect(closes, 1);
      expect(find.text('1 di 2'), findsOneWidget);
    });

    testWidgets('Continua on the last page closes and acks all (D-05)', (
      tester,
    ) async {
      var closes = 0;
      await _pump(tester, [_won, _lost], onContinue: () => closes++);

      await _swipe(tester, -600);
      await tester.tap(_continueOf(_lost));
      await tester.pumpAndSettle();

      expect(closes, 1);
    });

    testWidgets('every page is the result sheet with the ambush header '
        '(D-04, D-05)', (tester) async {
      await _pump(tester, [_won, _lost]);

      expect(find.text('Imboscata presso Andogan'), findsNWidgets(2));
      expect(find.byType(QuestResultSheet), findsNWidgets(2));
    });
  });

  group('AmbushReportCarousel affordance (D-19)', () {
    testWidgets(
      'with several reports the next page peeks in from the right edge (D-19)',
      (tester) async {
        await _pump(tester, [_won, _lost]);

        final w = _viewportWidth(tester);
        final p1 = tester.getRect(_page(_won));
        final p2 = tester.getRect(_page(_lost));
        expect(p1.width, closeTo(w * _peekViewportFraction, 1));
        expect(p1.left, closeTo(w * _peekEdge, 1));
        expect(p2.left, closeTo(w * (1 - _peekEdge), 1));
        expect(p2.left, lessThan(w));

        final parchment2 = tester.getRect(_parchmentOf(_lost));
        expect(parchment2.left, greaterThan(w / 2));
        expect(w - parchment2.left, greaterThanOrEqualTo(w * _minVisiblePeek));
      },
    );

    testWidgets(
      'on a later page the previous one peeks in from the left edge (D-19)',
      (tester) async {
        await _pump(tester, [_won, _lost]);

        await _swipe(tester, -300);

        final w = _viewportWidth(tester);
        final p1 = tester.getRect(_page(_won));
        final p2 = tester.getRect(_page(_lost));
        expect(p2.left, closeTo(w * _peekEdge, 1));
        expect(p1.right, closeTo(w * _peekEdge, 1));
        expect(p1.right, greaterThan(0));

        final parchment1 = tester.getRect(_parchmentOf(_won));
        expect(parchment1.right, lessThan(w / 2));
        expect(parchment1.right, greaterThanOrEqualTo(w * _minVisiblePeek));
        expect(find.text('2 di 2'), findsOneWidget);
      },
    );

    testWidgets(
      'a single report fills the viewport and nothing peeks in (D-19)',
      (tester) async {
        await _pump(tester, [_won]);

        final w = _viewportWidth(tester);
        final p1 = tester.getRect(_page(_won));
        expect(p1.width, closeTo(w, 1));
        expect(p1.left, closeTo(0, 1));
      },
    );
  });

  group('AmbushReportCarousel opening nudge (D-19)', () {
    testWidgets(
      'the nudge rests before moving, then moves and settles back (D-19)',
      (tester) async {
        await _pumpUnsettled(tester, [_won, _lost]);
        final w = _viewportWidth(tester);
        final restLeft = w * _peekEdge;

        await tester.pump(_nudgeDelay - const Duration(milliseconds: 50));
        expect(tester.getRect(_page(_won)).left, closeTo(restLeft, 0.5));

        await tester.pump(const Duration(milliseconds: 210));
        final shift = restLeft - tester.getRect(_page(_won)).left;
        expect(shift, greaterThan(0));
        expect(shift, lessThanOrEqualTo(w * _nudgeFraction + 1));

        await tester.pumpAndSettle();
        expect(tester.getRect(_page(_won)).left, closeTo(restLeft, 0.5));
        expect(
          tester.getRect(_page(_lost)).left,
          closeTo(w * (1 - _peekEdge), 0.5),
        );
        expect(find.text('1 di 2'), findsOneWidget);
      },
    );

    testWidgets('the nudge waits for the route transition to complete (D-19)', (
      tester,
    ) async {
      await _pumpInDialog(tester, [_won, _lost]);
      final w = _viewportWidth(tester);
      final restLeft = w * _peekEdge;

      await tester.pump(const Duration(milliseconds: 200));
      expect(tester.getRect(_page(_won)).left, closeTo(restLeft, 0.5));

      // Frames at the end of the fade, at the end of the rest, mid-nudge.
      await tester.pump(_routeTransition - const Duration(milliseconds: 200));
      await tester.pump(_nudgeDelay);
      await tester.pump(const Duration(milliseconds: 160));
      final shift = restLeft - tester.getRect(_page(_won)).left;
      expect(shift, greaterThan(0));
      expect(shift, lessThanOrEqualTo(w * _nudgeFraction + 1));

      await tester.pumpAndSettle();
      expect(tester.getRect(_page(_won)).left, closeTo(restLeft, 0.5));
    });

    testWidgets('a single report does not move at opening (D-19)', (
      tester,
    ) async {
      await _pumpUnsettled(tester, [_won]);
      await tester.pump(_nudgeDelay + const Duration(milliseconds: 160));

      expect(tester.getRect(_page(_won)).left, closeTo(0, 0.5));

      await tester.pumpAndSettle();

      expect(tester.getRect(_page(_won)).left, closeTo(0, 0.5));
    });

    testWidgets('Continua during the nudge still closes (D-05, D-19)', (
      tester,
    ) async {
      var closes = 0;
      await _pumpUnsettled(tester, [_won, _lost], onContinue: () => closes++);
      await tester.pump(_nudgeDelay + const Duration(milliseconds: 100));

      await tester.tap(_continueOf(_won));
      await tester.pumpAndSettle();

      expect(closes, 1);
    });
  });
}
