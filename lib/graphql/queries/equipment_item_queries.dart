import '../fragments/fragments.dart';

class EquipmentItemQueries {
  static String get getAllEquipmentItems =>
      '''
    query equipmentItems {
      equipmentItems {
        ${EquipmentFragment.fields}
      }
    }
  ''';

  static String get getEquipmentItemsByIds =>
      '''
    query equipmentItemsByIds(\$ids: [String!]!) {
      equipmentItemsByIds(ids: \$ids) {
        ${EquipmentFragment.fields}
      }
    }
  ''';
}
