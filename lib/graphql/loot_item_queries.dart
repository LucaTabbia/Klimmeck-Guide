class LootItemQueries {
  static const String getAllLootItems = r'''
    query lootItems {
      lootItems {
        id
        name
        description
        rarity
        buyPrice {
          gold
          silver
          copper
        }
        sellPrice {
          gold
          silver
          copper
        }
        effect
        power
      }
    }
  ''';

  static const String getAllLootAssetsQuantity = r'''
    query lootAssetsQuantity {
      lootAssetsQuantity {
        quantity
        item {
          ... on LootItem {
            id
            name
            description
            rarity
            buyPrice {
              gold
              silver
              copper
            }
            sellPrice {
              gold
              silver
              copper
            }
            effect
            power
          }
        }
      }
    }
  ''';

  static const String getLootItemsByIds = r'''
    query lootItemsByIds($ids: [String!]!) {
      lootItemsByIds(ids: $ids) {
        id
        name
        description
        rarity
        buyPrice {
          gold
          silver
          copper
        }
        sellPrice {
          gold
          silver
          copper
        }
        effect
        power
      }
    }
  ''';
}
