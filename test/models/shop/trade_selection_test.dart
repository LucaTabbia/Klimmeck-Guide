import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/asset_quantity.dart';
import 'package:klimmeck_guide/models/city_shop.dart';
import 'package:klimmeck_guide/models/coins.dart';
import 'package:klimmeck_guide/models/pet.dart';
import 'package:klimmeck_guide/models/shop/trade_selection.dart';

import '../../helpers/fixtures/shop_fixtures.dart';

final _sword = AssetQuantity.fromJson(equipmentAssetJson());
final _twoSwords = AssetQuantity.fromJson(equipmentAssetJson(quantity: 2));
final _potion = AssetQuantity.fromJson(lootAssetJson());
final _horse = Pet.fromJson(petJson());
final _cat = Pet.fromJson(catPetJson());

final _poolWithSwordOnly = CityShop.fromJson(
  cityShopJson(equipment: [equipmentAssetJson()], loot: [], pets: []),
);

const _horseInput = {'item': 'pet-travel-horse', 'quantity': 1};

void main() {
  group('totals', () {
    test('an empty selection is empty and totals zero', () {
      const selection = TradeSelection();

      expect(selection.isEmpty, isTrue);
      expect(selection.total(isBuy: true), const Coins());
      expect(selection.total(isBuy: false), const Coins());
    });

    test('the buy total adds the pet buy prices to the assets (D-07)', () {
      final selection = const TradeSelection()
          .withAssets([_sword])
          .addPet(_horse);

      expect(selection.total(isBuy: true), const Coins(gold: 1, silver: 30));
    });

    test('the sell total adds the pet sell prices (D-07)', () {
      final selection = const TradeSelection().addPet(_horse);

      expect(selection.total(isBuy: false), const Coins(silver: 50));
    });
  });

  group('pets and assets', () {
    test('addPet adds a pet once (quantity is always 1, D-15)', () {
      final selection = const TradeSelection().addPet(_horse).addPet(_horse);

      expect(selection.pets, [_horse]);
      expect(selection.containsPet('pet-travel-horse'), isTrue);
    });

    test('removePet drops the pet by id', () {
      final selection = const TradeSelection()
          .addPet(_horse)
          .addPet(_cat)
          .removePet('pet-travel-horse');

      expect(selection.pets, [_cat]);
    });

    test('withAssets replaces the asset quantities and keeps the pets', () {
      final selection = const TradeSelection()
          .withAssets([_sword])
          .addPet(_horse)
          .withAssets([_potion]);

      expect(selection.assets, [_potion]);
      expect(selection.pets, [_horse]);
    });
  });

  group('toTransactionItems', () {
    test(
      'toTransactionItems splits equipment, loot and pets with quantity 1 (D-07)',
      () {
        final selection = const TradeSelection()
            .withAssets([_twoSwords, _potion])
            .addPet(_horse);

        expect(selection.toTransactionItems().toJson(), {
          'equipAssets': [
            {'item': 'e-sword', 'quantity': 2},
          ],
          'lootAssets': [
            {'item': 'l-potion', 'quantity': 1},
          ],
          'petAssets': [_horseInput],
        });
      },
    );

    test('toTransactionItems skips assets without an item id', () {
      final selection = const TradeSelection().withAssets([
        const AssetQuantity(item: null, quantity: 3),
      ]);

      expect(selection.toTransactionItems().toJson(), {
        'equipAssets': <Object>[],
        'lootAssets': <Object>[],
        'petAssets': <Object>[],
      });
    });
  });

  group('pool', () {
    test(
      'retainPurchasable keeps only what the new pool still sells (D-03)',
      () {
        final selection = const TradeSelection()
            .withAssets([_sword, _potion])
            .addPet(_horse);

        final retained = selection.retainPurchasable(
          _poolWithSwordOnly,
          owned: const [],
        );

        expect(retained, const TradeSelection().withAssets([_sword]));
      },
    );

    test(
      'retainPurchasable drops a pet the character now owns (WR-02, D-08)',
      () {
        final pool = CityShop.fromJson(cityShopJson(pets: [petJson()]));
        final selection = const TradeSelection()
            .withAssets([_sword])
            .addPet(_horse);

        final retained = selection.retainPurchasable(pool, owned: [_horse]);

        expect(retained.pets, isEmpty);
        expect(retained.assets, [_sword]);
      },
    );

    test('retainOwned drops a sold pet that left the inventory (WR-02)', () {
      final selection = const TradeSelection()
          .withAssets([_potion])
          .addPet(_horse);

      final retained = selection.retainOwned(const []);

      expect(retained.pets, isEmpty);
      expect(retained.assets, [_potion]);
    });

    test('retainOwned keeps a pet still owned (WR-02)', () {
      final selection = const TradeSelection().addPet(_horse);

      expect(selection.retainOwned([_horse]).pets, [_horse]);
    });

    test('purchasablePets hides the pets already owned (D-08)', () {
      expect(purchasablePets([_horse, _cat], [_horse]), [_cat]);
    });

    test(
      'purchasablePets keeps the pool order and never filters by sellable or price (rule 4)',
      () {
        final unsellable = Pet.fromJson(
          petJson(id: 'pet-camel', name: 'Cammello', sellable: false),
        );
        final free = Pet.fromJson(
          petJson(id: 'pet-turtle', name: 'Tartaruga', buyPrice: coinsJson()),
        );

        expect(purchasablePets([unsellable, _cat, free], const []), [
          unsellable,
          _cat,
          free,
        ]);
      },
    );
  });

  group('buildTransactionRequest', () {
    Map<String, dynamic> requestJson({
      required TradeSelection bought,
      required TradeSelection sold,
    }) => buildTransactionRequest(
      characterId: 'c-1',
      bought: bought,
      sold: sold,
      total: const Coins(gold: 1),
      isTotalPositive: false,
    ).toJson();

    test(
      'a purchase carries petAssets only on the bought side (D-07, D-08)',
      () {
        final json = requestJson(
          bought: const TradeSelection().addPet(_horse),
          sold: const TradeSelection(),
        );

        expect(json['boughtItems']['petAssets'], [_horseInput]);
        expect(json['soldItems']['petAssets'], isEmpty);
      },
    );

    test('a sale carries petAssets only on the sold side (D-07)', () {
      final json = requestJson(
        bought: const TradeSelection(),
        sold: const TradeSelection().addPet(_horse),
      );

      expect(json['soldItems']['petAssets'], [_horseInput]);
      expect(json['boughtItems']['petAssets'], isEmpty);
    });

    test(
      'the request never equips: its keys are only id, boughtItems, soldItems, isTotalPositive, total (D-08)',
      () {
        final json = requestJson(
          bought: const TradeSelection().addPet(_horse),
          sold: const TradeSelection(),
        );

        expect(json.keys, [
          'id',
          'boughtItems',
          'soldItems',
          'isTotalPositive',
          'total',
        ]);
      },
    );

    test(
      'a request built after a pool reload carries only what the city still sells (D-03)',
      () {
        final selection = const TradeSelection()
            .withAssets([_sword, _potion])
            .addPet(_horse);

        final json = requestJson(
          bought: selection.retainPurchasable(
            _poolWithSwordOnly,
            owned: const [],
          ),
          sold: const TradeSelection(),
        );

        expect(json['boughtItems']['equipAssets'], [
          {'item': 'e-sword', 'quantity': 1},
        ]);
        expect(json['boughtItems']['lootAssets'], isEmpty);
        expect(json['boughtItems']['petAssets'], isEmpty);
      },
    );
  });
}
