import '../fragments/fragments.dart';

class QuestSubscriptions {
  static String get questUpdated =>
      '''
    subscription OnQuestUpdated(\$questId: String!) {
      questUpdated(questId: \$questId) {
        ${QuestFragment.fields}
      }
    }
  ''';
}
