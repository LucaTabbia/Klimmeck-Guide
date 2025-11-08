class EquipmentItemQueries {
  static const String getAllEquipmentItems = r'''
    query equipmentItems {
      equipmentItems {
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
        equipType 
        addedSpell {
          id
          name
          useType
          energyDamage {
            type
            power
          }
        }
        damages {
          base {
            type
            power
          }
          energy {
            type
            power
          }
        }
      }
    }
  ''';

  static const String getAllEquipmentAssetsQuantity = r'''
    query equipmentAssetsQuantity($sellable: Boolean) {
      equipmentAssetsQuantity(sellable: $sellable) {
        quantity
        item {
          ... on EquipmentItem {
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
            equipType 
            addedSpell {
              id
              name
              useType
              energyDamage {
                type
                power
              }
            }
            damages {
              base {
                type
                power
              }
              energy {
                type
                power
              }
            }
          }
        }
      }
    }
  ''';

  static const String getEquipmentItemsByIds = r'''
    query equipmentItemsByIds($ids: [String!]!) {
      equipmentItemsByIds(ids: $ids) {
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
        equipType 
        addedSpell {
          id
          name
          useType
          energyDamage {
            type
            power
          }
        }
        damages {
          base {
            type
            power
          }
          energy {
            type
            power
          }
        }
      }
    }
  ''';
}
