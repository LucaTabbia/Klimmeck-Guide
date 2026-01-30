import 'coins_fragment.dart';

class LootFragment {
  static const String name = 'LootItemFields';

  static String get definition => '''
    fragment $name on LootItem {
      id
      name
      description
      rarity
      effect
      power
      buyPrice {
        ${CoinsFragment.fields}
      }
      sellPrice {
        ${CoinsFragment.fields}
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
  ''';

  static const String simpleFields = '''
    id
    name
    itemType
    rarity
  ''';
}

