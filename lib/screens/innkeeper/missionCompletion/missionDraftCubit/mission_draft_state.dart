part of 'mission_draft_cubit.dart';

sealed class MissionDraftState extends Equatable {
  const MissionDraftState();

  @override
  List<Object?> get props => [];
}

/// Lettura della bozza in corso: loader ammesso, l'oste ha aperto il flusso.
final class MissionDraftLoading extends MissionDraftState {
  const MissionDraftLoading();
}

/// La lettura è fallita: il retry è un `load()` esplicito.
final class MissionDraftLoadFailed extends MissionDraftState {
  const MissionDraftLoadFailed({required this.failure});

  final InnkeeperFailure failure;

  @override
  List<Object?> get props => [failure];
}

/// Nessuna bozza sul BE: la pagina «Inizia la missione» la crea solo su azione
/// esplicita (D-28), mai all'apertura.
final class MissionDraftAbsent extends MissionDraftState {
  const MissionDraftAbsent({
    this.isStarting = false,
    this.failure,
    this.failureSerial = 0,
  });

  final bool isStarting;

  /// Esito dell'ultimo avvio rifiutato: la pagina resta.
  final InnkeeperFailure? failure;

  /// Cresce a ogni rifiuto: lo stesso codice due volte resta un evento.
  final int failureSerial;

  @override
  List<Object?> get props => [isStarting, failure, failureSerial];
}

/// La bozza come la serve il BE (D-09): ogni risposta la sostituisce per intero.
final class MissionDraftReady extends MissionDraftState {
  const MissionDraftReady({
    required this.draft,
    this.isSubmitting = false,
    this.failure,
    this.failureSerial = 0,
  });

  final MissionDraft draft;

  /// Una chiamata in volo: ogni altra azione è ignorata.
  final bool isSubmitting;

  /// Esito dell'ultima azione rifiutata: la bozza servita resta com'era.
  final InnkeeperFailure? failure;

  /// Cresce a ogni rifiuto: lo stesso codice due volte resta un evento.
  final int failureSerial;

  /// `failure` è sempre sostituito: ometterlo lo azzera.
  MissionDraftReady copyWith({
    MissionDraft? draft,
    bool? isSubmitting,
    InnkeeperFailure? failure,
    int? failureSerial,
  }) => MissionDraftReady(
    draft: draft ?? this.draft,
    isSubmitting: isSubmitting ?? this.isSubmitting,
    failure: failure,
    failureSerial: failureSerial ?? this.failureSerial,
  );

  @override
  List<Object?> get props => [draft, isSubmitting, failure, failureSerial];
}

/// Missione chiusa dal BE: i risultati creati, uno per partecipante.
final class MissionDraftCompleted extends MissionDraftState {
  const MissionDraftCompleted({required this.results});

  final List<QuestResult> results;

  @override
  List<Object?> get props => [results];
}

/// Bozza scartata: i partecipanti sono liberi (D-11).
final class MissionDraftDiscarded extends MissionDraftState {
  const MissionDraftDiscarded();
}
