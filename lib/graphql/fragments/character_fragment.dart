import 'coins_fragment.dart';
import 'equipment_fragment.dart';
import 'location_fragment.dart';
import 'loot_fragment.dart';
import 'spell_fragment.dart';

class CharacterFragment {
  static const String name = 'CharacterFields';

  static const String infosFields = '''
    infos {
      age
      background
      classType
      imagePath
      name
      pronoun
      race
      sex
    }
  ''';

  static String get statusFields => '''
    status {
      coins {
        ${CoinsFragment.fields}
      }
      currentLifePoints
      maxLifePoints
      maxActiveSpells
      injuries
      level
      xp
      title
      location {
        ${LocationFragment.fields}
      }
      spells {
        ${SpellFragment.fields}
      }
    }
  ''';

  static String get assetsFields => '''
    assets {
      wearedEquipment {
        ${WearedEquipmentFragment.withFields(EquipmentFragment.fieldsWithFullSpell)}
      }
      ownedEquipments {
        quantity
        item {
          ... on EquipmentItem {
            ${EquipmentFragment.fieldsWithFullSpell}
          }
        }
      }
      activeSpells {
        usages
        spell {
          ${SpellFragment.fields}
        }
      }
      ownedItems {
        quantity
        item {
          ... on LootItem {
            ${LootFragment.fields}
          }
        }
      }
    }
  ''';

  static const String questsFields = '''
    quests {
      completedQuests {
        id
      }
      pendingQuest {
        id
      }
    }
  ''';

  static String get fullFields => '''
    id
    $infosFields
    $statusFields
    $assetsFields
    $questsFields
  ''';
}

