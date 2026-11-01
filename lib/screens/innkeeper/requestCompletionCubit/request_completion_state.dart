part of 'request_completion_cubit.dart';

sealed class RequestCompletionState extends Equatable {
  const RequestCompletionState();

  @override
  List<Object?> get props => [];
}

/// Letture dei partecipanti in corso: loader ammesso, il GM ha aperto il form.
final class RequestCompletionLoading extends RequestCompletionState {
  const RequestCompletionLoading();
}

/// Una lettura è fallita: il retry è un `load()` esplicito (10-CONTEXT D-12).
final class RequestCompletionLoadFailed extends RequestCompletionState {
  const RequestCompletionLoadFailed({required this.failure});

  final InnkeeperFailure failure;

  @override
  List<Object?> get props => [failure];
}

/// Form aperto (10-CONTEXT D-11/D-12): i default significano «nessun cambiamento».
final class RequestCompletionEditing extends RequestCompletionState {
  const RequestCompletionEditing({
    required this.drafts,
    this.isSubmitting = false,
    this.failure,
    this.failureSerial = 0,
  });

  final List<ParticipantDraft> drafts;
  final bool isSubmitting;

  /// Esito dell'ultimo invio fallito, il form resta (D-14/C2).
  final InnkeeperFailure? failure;

  /// Cresce a ogni invio fallito: lo stesso codice due volte resta un evento.
  final int failureSerial;

  List<ParticipantOverride> get overrides => overridesOf(drafts);

  /// `failure` è sempre sostituito: ometterlo lo azzera.
  RequestCompletionEditing copyWith({
    List<ParticipantDraft>? drafts,
    bool? isSubmitting,
    InnkeeperFailure? failure,
    int? failureSerial,
  }) => RequestCompletionEditing(
    drafts: drafts ?? this.drafts,
    isSubmitting: isSubmitting ?? this.isSubmitting,
    failure: failure,
    failureSerial: failureSerial ?? this.failureSerial,
  );

  @override
  List<Object?> get props => [drafts, isSubmitting, failure, failureSerial];
}

/// Richiesta chiusa: i risultati creati, uno per partecipante.
final class RequestCompletionSucceeded extends RequestCompletionState {
  const RequestCompletionSucceeded({required this.results});

  final List<QuestResult> results;

  @override
  List<Object?> get props => [results];
}
