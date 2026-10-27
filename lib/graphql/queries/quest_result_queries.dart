import '../fragments/fragments.dart';

class QuestResultQueries {
  static String get getQuestResult =>
      '''
    query GetQuestResult(\$id: String!) {
      questResult(id: \$id) {
        ${QuestResultFragment.fields}
      }
    }
  ''';
}
