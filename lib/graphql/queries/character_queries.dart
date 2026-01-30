import '../fragments/fragments.dart';

class CharacterQueries {
  static String get getCharacter => '''
    query character(\$id: String!) {
      character(id: \$id) {
        ${CharacterFragment.fullFields}
      }
    }
  ''';

  static String get getEquipment => '''
    query equipment(\$id: String!) {
      equipment(id: \$id) {
        ${WearedEquipmentFragment.withFields(EquipmentFragment.fields)}
      }
    }
  ''';
}
