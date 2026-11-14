import '../fragments/fragments.dart';
import '../fragments/mission_draft_fragment.dart';

class MissionQueries {
  /// Bozza servita della richiesta (D-09, D-17): null se l'oste non l'ha
  /// ancora iniziata; raggiungibile da qualsiasi voce della carta (D-18).
  static String get getMissionDraft =>
      '''
    query GetMissionDraft(\$pendingQuestId: ID!) {
      missionDraft(pendingQuestId: \$pendingQuestId) {
        ${MissionDraftFragment.fields}
      }
    }
  ''';

  /// Nemici proposti all'oste (D-03, D-19): già filtrati e ordinati dal BE;
  /// `showAll` è l'interruttore «Mostra tutti».
  static String get listMissionEnemies =>
      '''
    query ListMissionEnemies(\$pendingQuestId: ID!, \$showAll: Boolean) {
      missionEnemies(pendingQuestId: \$pendingQuestId, showAll: \$showAll) {
        ${MissionEnemyFragment.fields}
      }
    }
  ''';

  /// Blocco del rango del personaggio e catalogo filtrato per rango (D-07,
  /// D-22): l'app non filtra mai premi per rango o rarità.
  static String get getMissionPrizeOptions =>
      '''
    query GetMissionPrizeOptions(\$characterId: ID!, \$pendingQuestId: ID!) {
      missionPrizeOptions(characterId: \$characterId, pendingQuestId: \$pendingQuestId) {
        character
        title
        maxRarity
        block {
          prizeCoins {
            ${CoinsFragment.fields}
          }
          xpPrize
          prizeItem {
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
          pet {
            ${PetFragment.fields}
          }
          spell {
            ${SpellFragment.simpleFields}
          }
          cure {
            lifePointsShare
            canHeal
          }
        }
        equipment {
          ${EquipmentFragment.simpleFields}
        }
        loot {
          ${LootFragment.simpleFields}
        }
        pets {
          ${PetFragment.fields}
        }
        spells {
          ${SpellFragment.simpleFields}
        }
      }
    }
  ''';
}
