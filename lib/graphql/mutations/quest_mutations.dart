class QuestMutations {
  /// Accetta una quest della board per il personaggio corrente (BE Phase 7).
  static const String acceptQuest = r'''
    mutation AcceptQuest($request: AcceptQuestRequest!) {
      acceptQuest(request: $request) {
        response
        successful
      }
    }''';

  /// Lascia il gruppo in attesa sul marker (BE Phase 9, 09-19). Lo stato non
  /// si costruisce dalla risposta: la corsia si svuota via `characterUpdated`.
  static const String abandonQuest = r'''
    mutation AbandonQuest($request: AbandonQuestRequest!) {
      abandonQuest(request: $request) {
        successful
      }
    }''';
}
