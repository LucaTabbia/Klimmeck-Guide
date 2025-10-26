class QuestQueries {
  static const String getAllQuests = r'''
    query quests {
  quests {
    id
    prizes {
      prizeCoins {
        copper
        gold
        silver
      }
      prizeItem {
        quantity
        item {
          ... on EquipmentItem {
            addedSpell {
              energyDamage {
                power
                type
              }
              id
              maxUsages
              minXpToLearn
              name
              recoveryTime
              requiredLearnTime
              useType
            }
            buyPrice {
              copper
              gold
              silver
            }
            damages {
              base {
                power
                type
              }
              energy {
                power
                type
              }
            }
            description
            equipType
            id
            name
            rarity
            sellPrice {
              copper
              gold
              silver
            }
          }
          ... on LootItem {
            buyPrice {
              copper
              gold
              silver
            }
            description
            effect
            id
            name
            power
            rarity
            sellPrice {
              copper
              gold
              silver
            }
          }
        }
      }
      randomLoot {
        item {
          ... on EquipmentItem {
            description
            equipType
            id
            name
            rarity
            addedSpell {
              energyDamage {
                power
                type
              }
              id
              maxUsages
              minXpToLearn
              name
              recoveryTime
              requiredLearnTime
              useType
            }
            buyPrice {
              copper
              gold
              silver
            }
            damages {
              base {
                power
                type
              }
              energy {
                power
                type
              }
            }
            sellPrice {
              copper
              gold
              silver
            }
          }
          ... on LootItem {
            description
            effect
            id
            name
            power
            rarity
            buyPrice {
              copper
              gold
              silver
            }
            sellPrice {
              copper
              gold
              silver
            }
          }
        }
        quantity
      }
      xpPrize
    }
  }
}
  ''';
}
