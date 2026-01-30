import '../fragments/fragments.dart';

class CharacterSubscriptions {
  static String get characterUpdated => '''
    subscription characterUpdated(\$id: String!) {
      characterUpdated(id: \$id) {
        ${CharacterFragment.fullFields}
      }
    }
  ''';
}
