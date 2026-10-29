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

  /// Risultati dell'utente non ancora confermati, dal più vecchio, al massimo
  /// 50 (BE 9.2 D-02).
  static String get listUnacknowledgedQuestResults =>
      '''
    query ListUnacknowledgedQuestResults {
      unacknowledgedQuestResults {
        ${QuestResultFragment.fields}
      }
    }
  ''';
}
