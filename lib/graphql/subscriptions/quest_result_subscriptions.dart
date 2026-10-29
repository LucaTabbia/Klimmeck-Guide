import '../fragments/fragments.dart';

class QuestResultSubscriptions {
  static String get questResultReceived =>
      '''
    subscription OnQuestResultReceived(\$characterId: String!) {
      questResultReceived(characterId: \$characterId) {
        ${QuestResultFragment.fields}
      }
    }
  ''';
}
