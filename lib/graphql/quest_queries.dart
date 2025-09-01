class QuestQueries {
  static const String getAllQuests = r'''
    query GetAllQuests {
      allQuests {
        id
        name
      }
    }
  ''';
}
