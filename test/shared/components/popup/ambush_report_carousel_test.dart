import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/config/cloudinary_assets.dart';
import 'package:klimmeck_guide/models/quest_result/quest_result.dart';
import 'package:klimmeck_guide/shared/components/popup/ambush_report_carousel.dart';
import 'package:klimmeck_guide/shared/components/popup/quest_result_sheet.dart';

import '../../../helpers/fixtures/quest_result_fixtures.dart';
import '../../../helpers/landscape.dart';
import '../../../helpers/svg_cache_seed.dart';
import '../../../helpers/test_app.dart';

final QuestResult _won = questResult(ambushWonResultJson());
final QuestResult _lost = questResult(ambushLostResultJson());

Future<void> _pump(
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
      expect(find.text('Sconfitta'), findsNothing);
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

      await tester.tap(find.byKey(QuestResultSheet.continueKey));
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
      await tester.tap(find.byKey(QuestResultSheet.continueKey));
      await tester.pumpAndSettle();

      expect(closes, 1);
    });

    testWidgets('every page is the result sheet with the ambush header '
        '(D-04, D-05)', (tester) async {
      await _pump(tester, [_won, _lost]);

      expect(find.text('Imboscata presso Andogan'), findsOneWidget);
      expect(find.byType(QuestResultSheet), findsOneWidget);
    });
  });
}
