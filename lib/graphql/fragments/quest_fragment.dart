import 'coins_fragment.dart';
import 'equipment_fragment.dart';
import 'location_fragment.dart';
import 'loot_fragment.dart';

/// Selezione di una quest condivisa dalla lista e dalla subscription
/// `questUpdated`: una sola forma, un solo parser.
class QuestFragment {
  static const String fields =
      '''
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
  ''';
}
