import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/models/enums/injury_type.dart';
import 'package:klimmeck_guide/models/pending_request/request_card.dart';
import 'package:klimmeck_guide/models/quest_result/quest_result.dart';
import 'package:klimmeck_guide/models/request/complete_pending_request_input.dart';
import 'package:klimmeck_guide/models/request/participant_draft.dart';
import 'package:klimmeck_guide/models/request/participant_override.dart';
import 'package:klimmeck_guide/repository/innkeeper_failure.dart';
import 'package:klimmeck_guide/repository/innkeeper_repository.dart';
import 'package:klimmeck_guide/shared/bloc/safe_emit.dart';

part 'request_completion_state.dart';

/// Completamento di una richiesta dal form del GM (10-CONTEXT D-11..D-14):
/// legge i partecipanti, applica le modifiche nei limiti del BE, invia una sola
/// chiamata con i soli partecipanti cambiati. Vive con la route del form.
class RequestCompletionCubit extends Cubit<RequestCompletionState>
    with SafeEmit<RequestCompletionState> {
  RequestCompletionCubit({
    required InnkeeperRepository repository,
    required RequestCard card,
  }) : _repository = repository,
       _card = card,
       super(const RequestCompletionLoading());

  final InnkeeperRepository _repository;
  final RequestCard _card;
  bool _isLoading = false;

  Future<void> load() async {
    if (!_canLoad) return;
    _isLoading = true;
    if (state is! RequestCompletionLoading) {
      emit(const RequestCompletionLoading());
    }
    try {
      emit(RequestCompletionEditing(drafts: await _readDrafts()));
    } on InnkeeperException catch (error) {
      emit(RequestCompletionLoadFailed(failure: error.failure));
    } on Object {
      // dati inattesi fuori dal repository (es. ParticipantDraft.from): mai
      // un loader infinito
      emit(
        const RequestCompletionLoadFailed(failure: InnkeeperFailure.malformed),
      );
    } finally {
      _isLoading = false;
    }
  }

  /// Solo all'apertura o al retry, mai due letture insieme.
  bool get _canLoad =>
      !_isLoading &&
      (state is RequestCompletionLoading ||
          state is RequestCompletionLoadFailed);

  void setHp(String characterId, int hp) =>
      _edit(characterId, (draft) => draft.withHp(hp));

  void toggleInjury(String characterId, InjuryType injury) =>
      _edit(characterId, (draft) => draft.withInjuryToggled(injury));

  void setConsumableUsed(String characterId, String itemId, int quantity) =>
      _edit(characterId, (draft) => draft.withConsumableUsed(itemId, quantity));

  void setSpellUsed(String characterId, String spellId, int usages) =>
      _edit(characterId, (draft) => draft.withSpellUsed(spellId, usages));

  /// Una sola chiamata con l'id della prima voce: chiude la richiesta per
  /// tutti i partecipanti (D-05, BE 09 §9). Un fallimento lascia il form com'è.
  Future<void> submit() async {
    final current = state;
    if (current is! RequestCompletionEditing || current.isSubmitting) return;
    emit(current.copyWith(isSubmitting: true));
    try {
      final results = await _repository.complete(
        CompletePendingRequestInput(
          pendingQuestId: _card.pendingQuestId,
          outcomes: current.overrides,
        ),
      );
      emit(RequestCompletionSucceeded(results: results));
    } on InnkeeperException catch (error) {
      emit(
        current.copyWith(
          isSubmitting: false,
          failure: error.failure,
          failureSerial: current.failureSerial + 1,
        ),
      );
    }
  }

  Future<List<ParticipantDraft>> _readDrafts() async {
    final participants = _card.participants;
    final characters = await Future.wait(
      participants.map(
        (participant) => _repository.readCharacter(participant.id),
      ),
    );
    return List.unmodifiable([
      for (final (index, character) in characters.indexed)
        ParticipantDraft.from(
          character,
          fallbackName: participants[index].name,
        ),
    ]);
  }

  void _edit(
    String characterId,
    ParticipantDraft Function(ParticipantDraft draft) change,
  ) {
    final current = state;
    if (current is! RequestCompletionEditing || current.isSubmitting) return;
    if (!current.drafts.any((draft) => draft.characterId == characterId)) {
      return;
    }
    emit(
      current.copyWith(
        drafts: List.unmodifiable(
          current.drafts.map(
            (draft) => draft.characterId == characterId ? change(draft) : draft,
          ),
        ),
      ),
    );
  }
}
