import '../fragments/fragments.dart';

class PendingRequestSubscriptions {
  /// Snapshot alla sottoscrizione, poi la lista intera a ogni insert/delete di
  /// PendingQuest (BE 09 §9, solo innkeeper).
  static String get pendingRequestsUpdated =>
      '''
    subscription OnPendingRequestsUpdated {
      pendingRequestsUpdated {
        ${PendingRequestFragment.fields}
      }
    }
  ''';
}
