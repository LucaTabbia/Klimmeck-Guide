class QuestQueries {
  static const String getAllQuests = r'''
    query quests {
      quests {
        id
        infos {
          enemy {
            id
          }
        markerLocation {
          latitude
          longitude
        }
        relatedLore {
          id
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
        prizeItem {
          id
        }
        randomLoot {
          item
          quantity
        }
        xpPrize
      }
      registeredAdventurers
      requirements {
        minTitle
        recommendedLoot {
          item
          quantity
        }
        requiredAdventurers
        requiredPoints
      }
    }
  }
  ''';
}
