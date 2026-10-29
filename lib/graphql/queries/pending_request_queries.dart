import '../fragments/fragments.dart';

class PendingRequestQueries {
  /// Coda delle richieste in attesa del GM (BE 09 §9, solo innkeeper).
  static String get getPendingRequests =>
      '''
    query GetPendingRequests {
      pendingRequests {
        ${PendingRequestFragment.fields}
      }
    }
  ''';
}
