import '../fragments/fragments.dart';

class QuestQueries {
  static String get getAllQuests => '''
    query quests {
      quests {
        id
        infos {
          markerLocation {
            ${LocationFragment.fields}
          }
          timeToComplete
          title
          type
        }
        prizes {
          prizeCoins {
            ${CoinsFragment.fields}
          }
          xpPrize
          randomLoot {
            quantity
            item {
              ... on EquipmentItem {
                ${EquipmentFragment.simpleFields}
              }
              ... on LootItem {
                ${LootFragment.simpleFields}
              }
            }
          }
          prizeItem {
            quantity
            item {
              ... on EquipmentItem {
                ${EquipmentFragment.simpleFields}
              }
              ... on LootItem {
                ${LootFragment.simpleFields}
                description
              }
            }
          }
        }
      }
    }
  ''';
}
