class QuestResultMutations {
  /// Conferma un foglio chiuso (BE 9.2 D-03), idempotente. La conferma di una
  /// morte stacca il personaggio corrente (BE 9.2 D-12).
  static const String acknowledgeQuestResult = r'''
    mutation AcknowledgeQuestResult($id: String!) {
      acknowledgeQuestResult(id: $id) {
        successful
        response
      }
    }''';
}
