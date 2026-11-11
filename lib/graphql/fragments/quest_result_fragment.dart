import 'coins_fragment.dart';
import 'equipment_fragment.dart';
import 'loot_fragment.dart';

/// Riepilogo di un esito (BE Phase 9 §1, 09-CONTEXT D-03/C5): le varianti di
/// ItemUnion selezionano equipType, senza il quale AssetItem.fromJson legge un
/// equipaggiamento come loot. Mai `locations` né campi di lore sotto un nemico
/// (BE §14, BE Phase 13 populate a profondità 1). `acknowledgedAt` è il campo
/// della BE 9.2 (null finché il foglio non è confermato). `enemies`,
/// `stagesCleared`, `stagesTotal` e `rewards.pet` sono della BE Phase 13 (D-07).
/// `kind` e `ambush` sono della BE Phase 15 (16-CONTEXT D-01): `quest` è null
/// per un'imboscata. `known` sotto `enemies` è della BE Phase 16 (17-CONTEXT D-03).
/// `loreUnlocked` è della BE Phase 16 (17-CONTEXT D-04): solo le novità dell'esito.
/// `injuriesHealed` è della BE Phase 18 (18-CONTEXT D-02); `arrested`,
/// `coinsLost` e `guardEncounter` sono della quick 261110-cgd (BE §1.6).
/// `petXpGained` è della BE Phase 19 (19-CONTEXT D-03): i PE del compagno.
class QuestResultFragment {
  static const String fields =
      '''
    id
    outcome
    kind
    resolvedAt
    acknowledgedAt
    character
    user
    quest {
      id
      type
      title
    }
    hpBefore
    hpAfter
    maxLifePoints
    injuriesAdded
    injuriesHealed
    arrested
    coinsLost {
      ${CoinsFragment.fields}
    }
    guardEncounter
    consumablesUsed {
      quantity
      item {
        ... on EquipmentItem {
          ${EquipmentFragment.simpleFields}
          description
        }
        ... on LootItem {
          ${LootFragment.simpleFields}
          description
          effect
          power
        }
      }
    }
    spellsUsed {
      usages
      spell {
        id
        name
      }
    }
    rewards {
      coins {
        ${CoinsFragment.fields}
      }
      items {
        quantity
        item {
          ... on EquipmentItem {
            ${EquipmentFragment.simpleFields}
            description
          }
          ... on LootItem {
            ${LootFragment.simpleFields}
            description
            effect
            power
          }
        }
      }
      pet {
        id
        name
      }
    }
    xpBefore
    xpGained
    xpAfter
    petXpGained
    levelBefore
    levelAfter
    titleBefore
    titleAfter
    spellLearned {
      id
      name
    }
    loreUnlocked {
      id
      name
      type
    }
    enemies {
      quantity
      known
      enemy {
        id
        name
        imagePath
        xp
      }
    }
    stagesCleared
    stagesTotal
    rescuedCharacters
    ambush {
      at
      nearCity {
        id
        name
      }
      reachedCity {
        id
        name
      }
    }
  ''';
}
