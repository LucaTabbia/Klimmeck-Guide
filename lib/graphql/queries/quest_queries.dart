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
          enemy {
            id
            name
            imagePath
          }
          relatedLore {
            id
            name
            description
          }
        }
        registeredAdventurers {
          character
          title
        }
        requirements {
          minTitle
          requiredPoints
          requiredAdventurers {
            title
            count
          }
          recommendedLoot {
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
                effect
                power
              }
            }
          }
        }
      }
    }
  ''';
}
