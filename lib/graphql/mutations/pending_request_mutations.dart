import '../fragments/fragments.dart';

class PendingRequestMutations {
  /// Completa una richiesta per tutti i partecipanti (BE 09 §9): restituisce i
  /// risultati creati.
  static String get completePendingRequest =>
      '''
    mutation CompletePendingRequest(\$input: CompletePendingRequestInput!) {
      completePendingRequest(input: \$input) {
        ${QuestResultFragment.fields}
      }
    }
  ''';
}
