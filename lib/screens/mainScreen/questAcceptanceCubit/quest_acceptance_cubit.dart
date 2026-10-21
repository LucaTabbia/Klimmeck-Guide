import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/repository/quest_acceptance_failure.dart';
import 'package:klimmeck_guide/repository/quest_acceptance_repository.dart';
import 'package:klimmeck_guide/shared/bloc/safe_emit.dart';

part 'quest_acceptance_state.dart';

/// Accettazione con lo swipe (D-01/D-03): `QuestAccepted` è l'unico segnale per
/// passare alla mappa; corsia e saldo arrivano dalle subscription. Il banner
/// d'errore lo pubblica la Board con un BlocListener (un Cubit non chiama Cubit).
class QuestAcceptanceCubit extends Cubit<QuestAcceptanceState>
    with SafeEmit<QuestAcceptanceState> {
  QuestAcceptanceCubit(this._repository) : super(const QuestAcceptanceIdle());

  final QuestAcceptanceRepository _repository;

  Future<void> accept({
    required String characterId,
    required String questId,
  }) async {
    if (isClosed || state is QuestAccepting) return;
    emit(QuestAccepting(questId));
    try {
      await _repository.accept(characterId: characterId, questId: questId);
      emit(QuestAccepted(questId));
    } on QuestAcceptanceException catch (error) {
      emit(QuestAcceptanceFailed(questId, error.failure));
    } catch (_) {
      emit(QuestAcceptanceFailed(questId, QuestAcceptanceFailure.unknown));
    }
  }

  /// Dopo che la UI ha gestito l'esito: il prossimo strappo riparte pulito.
  void reset() {
    if (state is QuestAccepting) return;
    emit(const QuestAcceptanceIdle());
  }
}
