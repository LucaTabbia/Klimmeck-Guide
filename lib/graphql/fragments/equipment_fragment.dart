import 'coins_fragment.dart';
import 'damage_fragment.dart';
import 'spell_fragment.dart';

class EquipmentFragment {
  static const String name = 'EquipmentItemFields';

  static String get definition => '''
    fragment $name on EquipmentItem {
      id
      name
      description
      rarity
      equipType
      buyPrice {
        ${CoinsFragment.fields}
      }
      sellPrice {
        ${CoinsFragment.fields}
      }
      damages {
        ${DamagesFragment.fields}
      }
      addedSpell {
        ${SpellFragment.simpleFields}
      }
    }
  ''';

  static const String fields = '''
    id
    name
    description
    rarity
    equipType
    buyPrice {
      gold
      silver
      copper
    }
    sellPrice {
      gold
      silver
      copper
    }
    damages {
      base {
        type
        power
      }
      energy {
        type
        power
      }
    }
    addedSpell {
      id
      name
      useType
      energyDamage {
        type
        power
      }
    }
  ''';

  static const String simpleFields = '''
    id
    name
    itemType
    equipType
    rarity
  ''';

  static String get fieldsWithFullSpell => '''
    id
    name
    description
    rarity
    equipType
    buyPrice {
      gold
      silver
      copper
    }
    sellPrice {
      gold
      silver
      copper
    }
    damages {
      base {
        type
        power
      }
      energy {
        type
        power
      }
    }
    addedSpell {
      ${SpellFragment.fields}
    }
  ''';
}

class WearedEquipmentFragment {
  static const String name = 'WearedEquipmentFields';

  static const List<String> slots = [
    'head',
    'chest',
    'legs',
    'arms',
    'leftHand',
    'rightHand',
    'firstAccessory',
    'secondAccessory',
    'foots',
  ];

  static String withFragment(String fragmentName) {
    return slots.map((slot) => '$slot { ...$fragmentName }').join('\n        ');
  }

  static String withFields(String fields) {
    return slots.map((slot) => '$slot { $fields }').join('\n        ');
  }
}

