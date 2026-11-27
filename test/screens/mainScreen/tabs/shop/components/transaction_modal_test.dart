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
import 'package:klimmeck_guide/shared/components/coins_display.dart';
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

Coins? _totalOf(WidgetTester tester) =>
    tester.widget<CoinsDisplay>(find.byKey(TransactionModal.totalKey)).coins;

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

  Future<void> pumpTransaction(
    WidgetTester tester, {
    required Character character,
    TradeSelection toBuy = const TradeSelection(),
    TradeSelection toSell = const TradeSelection(),
    bool? isAdd,
    void Function(Pet pet, String? name)? onCompanionInfo,
  }) async {
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
  }

  Future<void> open(WidgetTester tester, String section) async {
    await tester.tap(find.text(section));
    await tester.pumpAndSettle();
  }

  testWidgets('the receipt asks for no signature', (tester) async {
    await pumpTransaction(
      tester,
      character: _characterWith(coinsJson(gold: 2)),
      toBuy: TradeSelection(assets: [_sword]),
    );

    expect(find.textContaining('Firma'), findsNothing);
  });

  testWidgets('a net-positive sale reads a gain under the lists (D-14)', (
    tester,
  ) async {
    await pumpTransaction(
      tester,
      character: _characterWith(coinsJson(silver: 10)),
      toSell: TradeSelection(assets: [_swordSoldFor(coinsJson(silver: 50))]),
    );

    expect(_totalOf(tester), const Coins(silver: 50));
    expect(find.text('+'), findsOneWidget);
  });

  testWidgets('a purchase above the wallet still reads its cost', (
    tester,
  ) async {
    await pumpTransaction(
      tester,
      character: _characterWith(coinsJson(silver: 10)),
      toBuy: TradeSelection(assets: [_sword]),
    );

    expect(_totalOf(tester), const Coins(silver: 30));
    expect(find.text('-'), findsOneWidget);
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
    await pumpTransaction(
      tester,
      character: _characterWith(coinsJson(gold: 2)),
      toBuy: TradeSelection(assets: [_sword], pets: [_horse]),
    );

    expect(_totalOf(tester), const Coins(gold: 1, silver: 30));
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
