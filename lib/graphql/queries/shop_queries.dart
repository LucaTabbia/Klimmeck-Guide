import '../fragments/fragments.dart';

class ShopQueries {
  /// Pool della città del marker (D-01): solo l'id della città, mai il nome
  /// (D-02); taglia e `hasShop` arrivano con le città del cold start (D-04).
  static String get getCityShop =>
      '''
    query GetCityShop(\$cityId: ID!) {
      cityShop(cityId: \$cityId) {
        city {
          id
        }
        equipment {
          quantity
          item {
            ... on EquipmentItem {
              ${EquipmentFragment.fields}
            }
          }
        }
        loot {
          quantity
          item {
            ... on LootItem {
              ${LootFragment.fields}
            }
          }
        }
        pets {
          ${PetFragment.fields}
        }
      }
    }
  ''';
}
