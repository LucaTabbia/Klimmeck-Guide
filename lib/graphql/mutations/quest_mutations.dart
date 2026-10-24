class QuestMutations {
  /// Accetta una quest della board per il personaggio corrente (BE Phase 7).
  static const String acceptQuest = r'''
    mutation AcceptQuest($request: AcceptQuestRequest!) {
      acceptQuest(request: $request) {
        response
        successful
      }
    }''';
}
