import 'package:equatable/equatable.dart';
import 'package:klimmeck_guide/models/quest_result/quest_result.dart';

/// Esito del form per il pannello (10-CONTEXT D-13/D-14).
sealed class CompletionExit extends Equatable {
  const CompletionExit();

  @override
  List<Object?> get props => [];
}

/// Richiesta chiusa: i risultati, uno per partecipante.
final class CompletionCompleted extends CompletionExit {
  const CompletionCompleted(this.results);

  final List<QuestResult> results;

  @override
  List<Object?> get props => [results];
}

/// NOT_FOUND: completata altrove o sparita.
final class CompletionGone extends CompletionExit {
  const CompletionGone();
}

/// QUEST_IN_PROGRESS (BE-HARD-08).
final class CompletionBusy extends CompletionExit {
  const CompletionBusy();
}

/// FORBIDDEN: il ruolo non c'è più, il pannello si chiude (D-04).
final class CompletionForbidden extends CompletionExit {
  const CompletionForbidden();
}
