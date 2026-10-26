import '../fragments/fragments.dart';

class QuestQueries {
  static String get getAllQuests =>
      '''
    query quests {
      quests {
        ${QuestFragment.fields}
      }
    }
  ''';
}
