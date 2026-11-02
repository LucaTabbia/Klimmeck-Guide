import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/config/cloudinary_assets.dart';
import 'package:klimmeck_guide/models/asset_quantity.dart';
import 'package:klimmeck_guide/models/character/character.dart';
import 'package:klimmeck_guide/models/coins.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/shop/components/transaction_modal.dart';

import '../../../../../helpers/fixtures/shop_fixtures.dart';
import '../../../../../helpers/landscape.dart';
import '../../../../../helpers/svg_cache_seed.dart';
import '../../../../../helpers/test_app.dart';

/// Altezza del foglio reale: `PaperSheetModal` dà al figlio la larghezza
/// dello schermo come altezza, dentro uno scroll.
const double _sheetHeight = 780;

Character _characterWith(Map<String, dynamic> coins) => Character.fromJson({
  'id': 'c-1',
  'infos': {'name': 'Aldo', 'sex': 'male'},
  'status': {'title': 'rookie', 'coins': coins},
});

AssetQuantity _swordSoldFor(Map<String, dynamic> sellPrice) {
  final json = equipmentAssetJson();
  (json['item'] as Map<String, dynamic>)['sellPrice'] = sellPrice;
  return AssetQuantity.fromJson(json);
}

final _sword = AssetQuantity.fromJson(equipmentAssetJson());

Finder get _signatureLine => find.byWidgetPredicate(
  (widget) => widget is GestureDetector && widget.child is Stack,
);

Finder get _redCross => find.byWidgetPredicate(
  (widget) =>
      widget is CustomPaint &&
      widget.painter?.runtimeType.toString() == '_RedXPainter',
);

typedef _Confirmation = ({Coins total, bool isTotalPositive});

void main() {
  setUp(
    () => seedSvgCache([
      CloudinaryAssets.arrowDown,
      CloudinaryAssets.emptyCardSheet,
      CloudinaryAssets.goldCoin,
      CloudinaryAssets.silverCoin,
      CloudinaryAssets.copperCoin,
      CloudinaryAssets.weaponType,
    ]),
  );

  Future<List<_Confirmation>> pumpTransaction(
    WidgetTester tester, {
    required Character character,
    List<AssetQuantity> toBuy = const [],
    List<AssetQuantity> toSell = const [],
  }) async {
    final confirmations = <_Confirmation>[];
    useLandscapePhone(tester);
    await tester.pumpWidget(
      buildTestApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SizedBox(
              height: _sheetHeight,
              child: TransactionModal(
                itemsToBuy: toBuy,
                itemsToSell: toSell,
                onConfirm: (total, isTotalPositive) => confirmations.add((
                  total: total,
                  isTotalPositive: isTotalPositive,
                )),
                onChangedList: (_, _) {},
                character: character,
                onEquipmentInfo: (_) {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return confirmations;
  }

  Future<void> sign(WidgetTester tester) async {
    await tester.ensureVisible(_signatureLine);
    await tester.pumpAndSettle();
    await tester.tap(_signatureLine);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'a net-positive sale is signable with a wallet below the gain (D-14)',
    (tester) async {
      final confirmations = await pumpTransaction(
        tester,
        character: _characterWith(coinsJson(silver: 10)),
        toSell: [_swordSoldFor(coinsJson(silver: 50))],
      );

      expect(_redCross, findsNothing);
      await sign(tester);

      expect(confirmations, [
        (total: const Coins(silver: 50), isTotalPositive: true),
      ]);
    },
  );

  testWidgets('a purchase above the wallet is refused with the red cross', (
    tester,
  ) async {
    final confirmations = await pumpTransaction(
      tester,
      character: _characterWith(coinsJson(silver: 10)),
      toBuy: [_sword],
    );

    expect(_redCross, findsOneWidget);
    await sign(tester);

    expect(confirmations, isEmpty);
  });
}
