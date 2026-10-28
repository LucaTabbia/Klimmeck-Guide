import 'package:klimmeck_guide/models/quest_result/quest_result.dart';

/// Risultati dell'utente non ancora confermati (BE 9.2
/// `unacknowledgedQuestResults`, 09-CONTEXT D-09/C4). Lancia
/// `QuestResultException`. Il consumatore impone un timeout
/// (`QuestResultsCubit.portTimeout`, 09-REVIEW WR-04): una risposta che non
/// arriva diventa `TimeoutException`.
abstract interface class PendingQuestResults {
  Future<List<QuestResult>> fetchUnacknowledged();
}

/// Presa visione di un risultato (BE 9.2 `acknowledgeQuestResult`, D-10).
/// Lancia `QuestResultException`. Stesso timeout imposto dal consumatore: una
/// conferma appesa non deve bloccare la fila, morte compresa (WR-04).
abstract interface class QuestResultAcknowledger {
  Future<void> acknowledge(String resultId);
}

/// Finché il BE 9.2 non è su develop (piano 09-12): nessun risultato pendente.
class NoPendingQuestResults implements PendingQuestResults {
  const NoPendingQuestResults();

  @override
  Future<List<QuestResult>> fetchUnacknowledged() async => const [];
}

/// Finché il BE 9.2 non è su develop (piano 09-12): la conferma non parte.
class NoQuestResultAcknowledger implements QuestResultAcknowledger {
  const NoQuestResultAcknowledger();

  @override
  Future<void> acknowledge(String resultId) async {}
}
