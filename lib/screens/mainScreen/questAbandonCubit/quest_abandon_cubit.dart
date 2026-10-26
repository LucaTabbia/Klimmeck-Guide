import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/repository/quest_abandon_failure.dart';
import 'package:klimmeck_guide/repository/quest_abandon_repository.dart';
import 'package:klimmeck_guide/shared/bloc/safe_emit.dart';

part 'quest_abandon_state.dart';

/// Abbandono del gruppo in attesa sul marker (BE 09-19): nessuno stato dalla
/// risposta, la corsia si svuota via `characterUpdated`. L'avviso d'errore lo
/// pubblica QuestAbandonOutcomeListener (un Cubit non chiama Cubit).
class QuestAbandonCubit extends Cubit<QuestAbandonState>
    with SafeEmit<QuestAbandonState> {
  QuestAbandonCubit(this._repository) : super(const QuestAbandonIdle());

  final QuestAbandonRepository _repository;

  Future<void> abandon({
    required String characterId,
    required String questId,
  }) async {
    if (isClosed || state is QuestAbandoning) return;
    emit(QuestAbandoning(questId));
    try {
      await _repository.abandon(characterId: characterId, questId: questId);
      emit(QuestAbandoned(questId));
    } on QuestAbandonException catch (error) {
      emit(QuestAbandonFailed(questId, error.failure));
    } catch (_) {
      emit(QuestAbandonFailed(questId, QuestAbandonFailure.unknown));
    }
  }

  /// Dopo che la UI ha gestito l'esito: il prossimo abbandono riparte pulito.
  void reset() {
    if (state is QuestAbandoning) return;
    emit(const QuestAbandonIdle());
  }
}
