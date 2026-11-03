import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/config/cloudinary_assets.dart';
import 'package:klimmeck_guide/models/pet.dart';
import 'package:klimmeck_guide/shared/components/coins_display.dart';
import 'package:klimmeck_guide/shared/components/companion_row.dart';
import 'package:klimmeck_guide/utils/item_lines.dart';

import '../../helpers/fixtures/shop_fixtures.dart';
import '../../helpers/svg_cache_seed.dart';
import '../../helpers/test_app.dart';

const double _rowSize = 120;

final _horse = Pet.fromJson(petJson());
final _cat = Pet.fromJson(catPetJson());

Future<void> _pump(WidgetTester tester, CompanionRow row) async {
  await tester.pumpWidget(
    buildTestApp(
      home: Scaffold(body: SizedBox(width: 600, child: row)),
    ),
  );
  await tester.pump();
}

CoinsDisplay _coinsDisplay(WidgetTester tester) =>
    tester.widget<CoinsDisplay>(find.byType(CoinsDisplay));

void main() {
  setUp(
    () => seedSvgCache([
      CloudinaryAssets.goldCoin,
      CloudinaryAssets.silverCoin,
      CloudinaryAssets.copperCoin,
    ]),
  );

  testWidgets('shows the name and the buy price (D-07)', (tester) async {
    await _pump(tester, CompanionRow(pet: _horse, size: _rowSize));

    expect(find.text('Cavallo da viaggio'), findsOneWidget);
    expect(_coinsDisplay(tester).coins, _horse.buyPrice);
  });

  testWidgets('shows the sell price on the sell side (D-07)', (tester) async {
    await _pump(
      tester,
      CompanionRow(pet: _horse, size: _rowSize, isBuy: false),
    );

    expect(_coinsDisplay(tester).coins, _horse.sellPrice);
  });

  testWidgets('shows the speed line only for a mount (D-07)', (tester) async {
    await _pump(tester, CompanionRow(pet: _horse, size: _rowSize));
    expect(find.text('Velocità ×2'), findsOneWidget);

    await _pump(tester, CompanionRow(pet: _cat, size: _rowSize));
    expect(find.textContaining('Velocità'), findsNothing);
  });

  testWidgets('hides the coins in the Journal (D-10)', (tester) async {
    await _pump(
      tester,
      CompanionRow(pet: _horse, size: _rowSize, showCoins: false),
    );

    expect(find.byType(CoinsDisplay), findsNothing);
  });

  testWidgets('marks the equipped companion (D-10)', (tester) async {
    await _pump(
      tester,
      CompanionRow(pet: _horse, size: _rowSize, isEquipped: true),
    );
    expect(find.text(companionEquippedMark), findsOneWidget);

    await _pump(tester, CompanionRow(pet: _horse, size: _rowSize));
    expect(find.text(companionEquippedMark), findsNothing);
  });

  testWidgets('a tap calls onTap', (tester) async {
    var taps = 0;
    await _pump(
      tester,
      CompanionRow(pet: _horse, size: _rowSize, onTap: () => taps++),
    );

    await tester.tap(find.text('Cavallo da viaggio'));

    expect(taps, 1);
  });

  testWidgets('is text-only: no image (D-13)', (tester) async {
    await _pump(tester, CompanionRow(pet: _horse, size: _rowSize));

    expect(find.byType(Image), findsNothing);
  });
}
