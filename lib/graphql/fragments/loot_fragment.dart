import 'coins_fragment.dart';

class LootFragment {
  static const String name = 'LootItemFields';

  static String get definition =>
      '''
    fragment $name on LootItem {
      id
      name
      description
      rarity
      effect
      power
      canHeal
      buyPrice {
        ${CoinsFragment.fields}
      }
      sellPrice {
        ${CoinsFragment.fields}
      }
      recovery {
        time
        turns
      }
    }
  ''';

  static const String fields = '''
    id
    name
    description
    rarity
    effect
    power
    canHeal
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
    recovery {
      time
      turns
    }
  ''';

  static const String simpleFields = '''
    id
    name
    itemType
    rarity
  ''';
}
