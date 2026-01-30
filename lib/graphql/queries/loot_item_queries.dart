import '../fragments/fragments.dart';

class LootItemQueries {
  static String get getAllLootItems => '''
    query lootItems {
      lootItems {
        ${LootFragment.fields}
      }
    }
  ''';

  static String get getAllLootAssetsQuantity => '''
    query lootAssetsQuantity {
      lootAssetsQuantity {
        quantity
        item {
          ... on LootItem {
            ${LootFragment.fields}
          }
        }
      }
    }
  ''';

  static String get getLootItemsByIds => '''
    query lootItemsByIds(\$ids: [String!]!) {
      lootItemsByIds(ids: \$ids) {
        ${LootFragment.fields}
      }
    }
  ''';
}
