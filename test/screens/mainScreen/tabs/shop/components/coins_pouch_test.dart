import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/config/cloudinary_assets.dart';
import 'package:klimmeck_guide/models/coins.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/shop/components/coins_pouch.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/shop/components/purse_tag.dart';

import '../../../../../helpers/landscape.dart';
import '../../../../../helpers/svg_cache_seed.dart';
import '../../../../../helpers/test_app.dart';

const _shopkeeper = Offset(200, 120);

Finder get _pouch => find.byType(CoinsPouch);

double _scaleOf(WidgetTester tester) => tester
    .widget<Transform>(
      find.descendant(of: _pouch, matching: find.byKey(CoinsPouch.scaleKey)),
    )
    .transform
    .entry(0, 0);

Offset _restingCenter(WidgetTester tester) => tester.getCenter(_pouch);

Offset _displacementOf(WidgetTester tester) {
  final translation = tester
      .widget<Transform>(
        find.descendant(of: _pouch, matching: find.byKey(CoinsPouch.flightKey)),
      )
      .transform
      .getTranslation();
  return Offset(translation.x, translation.y);
}

void main() {
  setUp(
    () => seedSvgCache([
      CloudinaryAssets.coinsPouch,
      CloudinaryAssets.goldCoin,
      CloudinaryAssets.silverCoin,
      CloudinaryAssets.copperCoin,
    ]),
  );

  Future<List<void>> pumpPouch(
    WidgetTester tester, {
    bool canPay = true,
    Coins? purse,
  }) async {
    final deliveries = <void>[];
    useLandscapePhone(tester);
    await tester.pumpWidget(
      buildTestApp(
        home: Stack(
          children: [
            Positioned(
              right: 20,
              bottom: 20,
              child: CoinsPouch(
                width: 100,
                height: 100,
                shopkeeper: _shopkeeper,
                purse: purse,
                onDelivered: canPay ? () => deliveries.add(null) : null,
              ),
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    return deliveries;
  }

  testWidgets('a pouch dropped on the shopkeeper is delivered', (tester) async {
    final deliveries = await pumpPouch(tester);

    await tester.dragFrom(
      _restingCenter(tester),
      _shopkeeper - _restingCenter(tester),
    );
    await tester.pumpAndSettle();

    expect(deliveries, hasLength(1));
  });

  testWidgets('a pouch dropped halfway goes back to its corner', (
    tester,
  ) async {
    final deliveries = await pumpPouch(tester);
    final resting = _restingCenter(tester);

    await tester.dragFrom(resting, (_shopkeeper - resting) / 2);
    await tester.pumpAndSettle();

    expect(deliveries, isEmpty);
    expect(_displacementOf(tester), Offset.zero);
  });

  testWidgets('the pouch shrinks as it nears the shopkeeper', (tester) async {
    await pumpPouch(tester);
    final resting = _restingCenter(tester);
    final journey = _shopkeeper - resting;
    expect(_scaleOf(tester), 1);

    final gesture = await tester.startGesture(resting);
    await gesture.moveBy(journey * 0.4);
    await tester.pump();
    final halfwayScale = _scaleOf(tester);
    await gesture.moveBy(journey * 0.4);
    await tester.pump();
    final closeScale = _scaleOf(tester);
    await gesture.cancel();

    expect(halfwayScale, lessThan(1));
    expect(closeScale, lessThan(halfwayScale));
  });

  testWidgets('reads as a payment to the shopkeeper', (tester) async {
    await pumpPouch(tester);

    expect(find.bySemanticsLabel('Paga il negoziante'), findsOneWidget);
  });

  testWidgets('the tag on the pouch reads the purse', (tester) async {
    const purse = Coins(gold: 113, silver: 19, copper: 43);
    await pumpPouch(tester, purse: purse);

    final tag = tester.widget<PurseTag>(
      find.descendant(of: _pouch, matching: find.byType(PurseTag)),
    );
    expect(tag.coins, purse);
  });

  testWidgets('without a cart to pay the pouch stays put', (tester) async {
    final deliveries = await pumpPouch(tester, canPay: false);
    final resting = _restingCenter(tester);

    final gesture = await tester.startGesture(resting);
    await gesture.moveBy((_shopkeeper - resting) * 0.6);
    await tester.pump();
    expect(_displacementOf(tester), Offset.zero);
    await gesture.up();
    await tester.pumpAndSettle();

    expect(deliveries, isEmpty);
  });
}
