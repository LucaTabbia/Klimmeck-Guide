import 'coins_fragment.dart';
import 'equipment_fragment.dart';
import 'loot_fragment.dart';

/// Riepilogo di un esito (BE Phase 9 §1, 09-CONTEXT D-03/C5): le varianti di
/// ItemUnion selezionano equipType, senza il quale AssetItem.fromJson legge un
/// equipaggiamento come loot. Mai `enemy.locations` (BE §14). `acknowledgedAt`
/// è il campo della BE 9.2 (null finché il foglio non è confermato).
class QuestResultFragment {
  static const String fields =
      '''
    id
    outcome
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
    }
    xpBefore
    xpGained
    xpAfter
    levelBefore
    levelAfter
    titleBefore
    titleAfter
    spellLearned {
      id
      name
    }
    enemy {
      id
      name
      imagePath
    }
    rescuedCharacters
  ''';
}
