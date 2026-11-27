import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/config/cloudinary_assets.dart';
import 'package:klimmeck_guide/models/coins.dart';
import 'package:klimmeck_guide/models/enums/column_layout_type.dart';
import 'package:klimmeck_guide/shared/components/cached_svg.dart';
import 'package:klimmeck_guide/shared/components/coins_display.dart';

import '../../helpers/svg_cache_seed.dart';
import '../../helpers/test_app.dart';

List<String> _coinIcons(WidgetTester tester) => tester
    .widgetList<CachedSvg>(find.byType(CachedSvg))
    .map((svg) => svg.url)
    .toList();

String _url(String asset) => CloudinaryAssets.url(asset);

void main() {
  setUp(
    () => seedSvgCache([
      CloudinaryAssets.goldCoin,
      CloudinaryAssets.silverCoin,
      CloudinaryAssets.copperCoin,
    ]),
  );

  Future<void> pump(
    WidgetTester tester,
    Coins? coins, {
    CoinLayoutType layout = CoinLayoutType.column,
  }) async {
    await tester.pumpWidget(
      buildTestApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 300,
              child: CoinsDisplay(coins: coins, height: 90, layout: layout),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  for (final layout in CoinLayoutType.values) {
    group('${layout.name} layout', () {
      testWidgets('shows only the coins it holds', (tester) async {
        await pump(
          tester,
          const Coins(gold: 0, silver: 1, copper: 20),
          layout: layout,
        );

        expect(_coinIcons(tester), [
          _url(CloudinaryAssets.silverCoin),
          _url(CloudinaryAssets.copperCoin),
        ]);
        expect(find.text('1'), findsOneWidget);
        expect(find.text('20'), findsOneWidget);
        expect(find.text('0'), findsNothing);
      });

      testWidgets('no coins at all read a single copper 0', (tester) async {
        await pump(tester, const Coins(), layout: layout);

        expect(_coinIcons(tester), [_url(CloudinaryAssets.copperCoin)]);
        expect(find.text('0'), findsOneWidget);
      });

      testWidgets('a missing price reads a single copper 0', (tester) async {
        await pump(tester, null, layout: layout);

        expect(_coinIcons(tester), [_url(CloudinaryAssets.copperCoin)]);
      });
    });
  }
}
