import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/asset_quantity.dart';
import 'package:klimmeck_guide/models/coins.dart';
import 'package:klimmeck_guide/models/request/transaction_request.dart';

void main() {
  group('TransactionItems', () {
    test(
      'serialises petAssets with quantity 1 beside equip and loot assets (D-07)',
      () {
        final items = TransactionItems(
          equipAssets: [AssetQuantityInput(item: 'e-1', quantity: 2)],
          lootAssets: [],
          petAssets: [
            AssetQuantityInput(item: 'pet-travel-horse', quantity: 1),
          ],
        );

        expect(items.toJson(), {
          'equipAssets': [
            {'item': 'e-1', 'quantity': 2},
          ],
          'lootAssets': [],
          'petAssets': [
            {'item': 'pet-travel-horse', 'quantity': 1},
          ],
        });
      },
    );

    test('defaults petAssets to an empty list', () {
      final items = TransactionItems(equipAssets: [], lootAssets: []);

      expect(items.toJson()['petAssets'], isEmpty);
      expect(items.toJson()['petAssets'], isA<List<dynamic>>());
    });
  });

  group('TransactionRequest', () {
    test('TransactionRequest.toJson nests the three lists as plain maps', () {
      final request = TransactionRequest(
        id: 'c-1',
        boughtItems: TransactionItems(
          equipAssets: [],
          lootAssets: [AssetQuantityInput(item: 'l-1', quantity: 3)],
          petAssets: [AssetQuantityInput(item: 'pet-cat', quantity: 1)],
        ),
        soldItems: TransactionItems(
          equipAssets: [AssetQuantityInput(item: 'e-2', quantity: 1)],
          lootAssets: [],
        ),
        isTotalPositive: false,
        total: const Coins(silver: 20),
      );

      expect(request.toJson(), {
        'id': 'c-1',
        'boughtItems': {
          'equipAssets': [],
          'lootAssets': [
            {'item': 'l-1', 'quantity': 3},
          ],
          'petAssets': [
            {'item': 'pet-cat', 'quantity': 1},
          ],
        },
        'soldItems': {
          'equipAssets': [
            {'item': 'e-2', 'quantity': 1},
          ],
          'lootAssets': [],
          'petAssets': [],
        },
        'isTotalPositive': false,
        'total': {'gold': 0, 'silver': 20, 'copper': 0},
      });
    });
  });
}
