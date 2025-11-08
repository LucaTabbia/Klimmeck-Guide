class QuestQueries {
  static const String getAllQuests = r'''
    query quests {
  quests {
  id
    infos {
      markerLocation {
        id
        location
      }
      timeToComplete
      title
      type
    }
    prizes {
      prizeCoins {
        copper
        gold
        silver
      }
      randomLoot {
        item {
          ... on EquipmentItem {
            id
            itemType
            name
          }
          ... on LootItem {
            id
            name
            itemType
          }
        }
        quantity
      }
      prizeItem {
        item {
          ... on EquipmentItem {
            id
            itemType
            name
          }
          ... on LootItem {
            description
            id
            name
            itemType
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
