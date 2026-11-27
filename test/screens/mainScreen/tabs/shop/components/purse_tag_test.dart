import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/config/cloudinary_assets.dart';
import 'package:klimmeck_guide/models/coins.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/shop/components/purse_tag.dart';
import 'package:klimmeck_guide/shared/components/cached_svg.dart';

import '../../../../../helpers/svg_cache_seed.dart';
import '../../../../../helpers/test_app.dart';

List<String> _coinIcons(WidgetTester tester) => tester
    .widgetList<CachedSvg>(find.byType(CachedSvg))
    .map((svg) => svg.url)
    .toList();

void main() {
  setUp(
    () => seedSvgCache([
      CloudinaryAssets.goldCoin,
      CloudinaryAssets.silverCoin,
      CloudinaryAssets.copperCoin,
    ]),
  );

  Future<void> pump(WidgetTester tester, Coins? coins) async {
    await tester.pumpWidget(
      buildTestApp(
        home: Center(
          child: SizedBox(width: 30, height: 50, child: PurseTag(coins: coins)),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('writes one line per coin held, in pencil', (tester) async {
    await pump(tester, const Coins(gold: 113, silver: 0, copper: 43));

    expect(_coinIcons(tester), [
      CloudinaryAssets.url(CloudinaryAssets.goldCoin),
      CloudinaryAssets.url(CloudinaryAssets.copperCoin),
    ]);
    expect(find.text('113'), findsOneWidget);
    expect(find.text('43'), findsOneWidget);
  });

  testWidgets('an empty purse reads a single copper 0', (tester) async {
    await pump(tester, null);

    expect(_coinIcons(tester), [
      CloudinaryAssets.url(CloudinaryAssets.copperCoin),
    ]);
    expect(find.text('0'), findsOneWidget);
  });

  testWidgets('long amounts shrink to stay on the tag', (tester) async {
    await pump(tester, const Coins(gold: 123456, silver: 98765, copper: 4321));

    expect(tester.takeException(), isNull);
    final tag = tester.getRect(find.byType(PurseTag)).inflate(0.5);
    for (final text in ['123456', '98765', '4321']) {
      final rect = tester.getRect(find.text(text));
      expect(tag.contains(rect.topLeft), isTrue, reason: text);
      expect(tag.contains(rect.bottomRight), isTrue, reason: text);
    }
  });

  testWidgets('each line starts left of the one above, like the tag edge', (
    tester,
  ) async {
    await pump(tester, const Coins(gold: 1, silver: 2, copper: 3));

    final starts = [
      for (final asset in [
        CloudinaryAssets.goldCoin,
        CloudinaryAssets.silverCoin,
        CloudinaryAssets.copperCoin,
      ])
        tester
            .getTopLeft(
              find.byWidgetPredicate(
                (widget) =>
                    widget is CachedSvg &&
                    widget.url == CloudinaryAssets.url(asset),
              ),
            )
            .dx,
    ];
    expect(starts[0], greaterThan(starts[1]));
    expect(starts[1], greaterThan(starts[2]));
  });
}
