import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/config/cloudinary_assets.dart';
import 'package:klimmeck_guide/models/asset_quantity.dart';
import 'package:klimmeck_guide/models/character/character.dart';
import 'package:klimmeck_guide/models/coins.dart';
import 'package:klimmeck_guide/models/pet.dart';
import 'package:klimmeck_guide/models/shop/trade_selection.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/shop/components/transaction_modal.dart';
import 'package:klimmeck_guide/shared/components/cards/card_label.dart';
import 'package:klimmeck_guide/shared/components/cards/companion_card.dart';
import 'package:klimmeck_guide/shared/components/companion_row.dart';

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
final _horse = Pet.fromJson(petJson());

const _horseRowKey = ValueKey('trade-pet-pet-travel-horse');

Character _ownerOf(String name) => Character.fromJson({
  'id': 'c-1',
  'infos': {'name': 'Aldo', 'sex': 'male'},
  'status': {'title': 'rookie', 'coins': coinsJson(gold: 2)},
  'assets': {
    'ownedPets': [ownedPetJson(pet: petJson(), name: name)],
  },
});

typedef _InfoRequest = ({Pet pet, String? name});

Finder _companionIn(String dropdownKey) => find.descendant(
  of: find.byKey(ValueKey(dropdownKey)),
  matching: find.byType(CompanionRow),
);

Finder get _signatureLine => find.byWidgetPredicate(
  (widget) => widget is GestureDetector && widget.child is Stack,
);

Finder get _redCross => find.byWidgetPredicate(
  (widget) =>
      widget is CustomPaint &&
      widget.painter?.runtimeType.toString() == '_RedXPainter',
);

typedef _Confirmation = ({Coins total, bool isTotalPositive});

typedef _Change = ({TradeSelection selection, bool isBuy});

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

  final changes = <_Change>[];

  Future<List<_Confirmation>> pumpTransaction(
    WidgetTester tester, {
    required Character character,
    TradeSelection toBuy = const TradeSelection(),
    TradeSelection toSell = const TradeSelection(),
    bool? isAdd,
    void Function(Pet pet, String? name)? onCompanionInfo,
  }) async {
    final confirmations = <_Confirmation>[];
    changes.clear();
    useLandscapePhone(tester);
    await tester.pumpWidget(
      buildTestApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SizedBox(
              height: _sheetHeight,
              child: TransactionModal(
                toBuy: toBuy,
                toSell: toSell,
                onConfirm: (total, isTotalPositive) => confirmations.add((
                  total: total,
                  isTotalPositive: isTotalPositive,
                )),
                onChanged: (selection, isBuy) =>
                    changes.add((selection: selection, isBuy: isBuy)),
                character: character,
                isAdd: isAdd,
                onEquipmentInfo: (_) {},
                onCompanionInfo: onCompanionInfo,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return confirmations;
  }

  Future<void> open(WidgetTester tester, String section) async {
    await tester.tap(find.text(section));
    await tester.pumpAndSettle();
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
        toSell: TradeSelection(assets: [_swordSoldFor(coinsJson(silver: 50))]),
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
      toBuy: TradeSelection(assets: [_sword]),
    );

    expect(_redCross, findsOneWidget);
    await sign(tester);

    expect(confirmations, isEmpty);
  });

  testWidgets('lists the companions to buy under Acquisto (D-07)', (
    tester,
  ) async {
    await pumpTransaction(
      tester,
      character: _characterWith(coinsJson(gold: 2)),
      toBuy: TradeSelection(pets: [_horse]),
    );
    await open(tester, 'Acquisto');

    expect(_companionIn('buy_dropdown'), findsOneWidget);
    expect(_companionIn('sell_dropdown'), findsNothing);
    expect(find.text('Cavallo da viaggio'), findsOneWidget);
  });

  testWidgets('lists the companions to sell under Vendita (D-07)', (
    tester,
  ) async {
    await pumpTransaction(
      tester,
      character: _characterWith(coinsJson(gold: 2)),
      toSell: TradeSelection(pets: [_horse]),
    );
    await open(tester, 'Vendita');

    expect(_companionIn('sell_dropdown'), findsOneWidget);
    expect(_companionIn('buy_dropdown'), findsNothing);
  });

  testWidgets('includes companion prices in the total (D-07)', (tester) async {
    final confirmations = await pumpTransaction(
      tester,
      character: _characterWith(coinsJson(gold: 2)),
      toBuy: TradeSelection(assets: [_sword], pets: [_horse]),
    );
    await sign(tester);

    expect(confirmations, [
      (total: const Coins(gold: 1, silver: 30), isTotalPositive: false),
    ]);
  });

  testWidgets('the rubber removes a companion from the selection (D-07)', (
    tester,
  ) async {
    await pumpTransaction(
      tester,
      character: _characterWith(coinsJson(gold: 2)),
      toBuy: TradeSelection(assets: [_sword], pets: [_horse]),
      isAdd: false,
    );
    await open(tester, 'Acquisto');
    await tester.tap(find.byKey(const ValueKey('trade-pet-pet-travel-horse')));
    await tester.pumpAndSettle();

    expect(changes, [
      (selection: TradeSelection(assets: [_sword]), isBuy: true),
    ]);
    expect(_companionIn('buy_dropdown'), findsNothing);
  });

  testWidgets('the pencil leaves a companion selected once (D-07)', (
    tester,
  ) async {
    await pumpTransaction(
      tester,
      character: _characterWith(coinsJson(gold: 2)),
      toBuy: TradeSelection(pets: [_horse]),
      isAdd: true,
    );
    await open(tester, 'Acquisto');
    await tester.tap(find.byKey(const ValueKey('trade-pet-pet-travel-horse')));
    await tester.pumpAndSettle();

    expect(changes, isEmpty);
    expect(_companionIn('buy_dropdown'), findsOneWidget);
  });

  testWidgets('long press on a basket companion asks for its details (D-35)', (
    tester,
  ) async {
    final requests = <_InfoRequest>[];
    await pumpTransaction(
      tester,
      character: _characterWith(coinsJson(gold: 2)),
      toBuy: TradeSelection(pets: [_horse]),
      isAdd: false,
      onCompanionInfo: (pet, name) => requests.add((pet: pet, name: name)),
    );
    await open(tester, 'Acquisto');
    await tester.longPress(find.byKey(_horseRowKey));
    await tester.pumpAndSettle();

    expect(requests, [(pet: _horse, name: null)]);
    expect(changes, isEmpty);
    expect(_companionIn('buy_dropdown'), findsOneWidget);
  });

  testWidgets(
    'the sell side of the basket reads the owned companion\'s name (D-20)',
    (tester) async {
      final requests = <_InfoRequest>[];
      await pumpTransaction(
        tester,
        character: _ownerOf('Fulmine'),
        toSell: TradeSelection(pets: [_horse]),
        onCompanionInfo: (pet, name) => requests.add((pet: pet, name: name)),
      );
      await open(tester, 'Vendita');

      expect(
        tester
            .widget<CardLabel>(
              find.byKey(CompanionCard.titleKeyOf('pet-travel-horse')),
            )
            .text,
        'Fulmine',
      );
      await tester.longPress(find.byKey(_horseRowKey));
      await tester.pumpAndSettle();
      expect(requests, [(pet: _horse, name: 'Fulmine')]);
    },
  );

  testWidgets('the buy side of the basket reads the species (D-20)', (
    tester,
  ) async {
    await pumpTransaction(
      tester,
      character: _ownerOf('Fulmine'),
      toBuy: TradeSelection(pets: [_horse]),
    );
    await open(tester, 'Acquisto');

    expect(
      tester
          .widget<CardLabel>(
            find.byKey(CompanionCard.titleKeyOf('pet-travel-horse')),
          )
          .text,
      'Cavallo da viaggio',
    );
  });
}
