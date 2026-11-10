import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/models/use_item_result.dart';
import 'package:klimmeck_guide/repository/item_use_failure.dart';
import 'package:klimmeck_guide/repository/item_use_repository.dart';
import 'package:klimmeck_guide/shared/bloc/safe_emit.dart';

part 'potion_state.dart';

/// Bevuta di una pozione heal dal Diario (BE Phase 18, D-11). Non è
/// ottimistico: vita, scorta e ferite le decide il backend e arrivano dal
/// flusso del personaggio. L'avviso di un rifiuto lo pubblica
/// PotionOutcomeListener (un Cubit non chiama Cubit).
class PotionCubit extends Cubit<PotionState> with SafeEmit<PotionState> {
  PotionCubit(this._repository) : super(const PotionIdle());

  final ItemUseRepository _repository;
  int _refusals = 0;

  Future<void> drink(String itemId) async {
    if (isClosed || state is PotionDrinking) return;
    emit(PotionDrinking(itemId));
    try {
      final result = await _repository.useItem(itemId);
      emit(PotionDrunk(itemId, result));
    } on ItemUseException catch (error) {
      emit(_refused(itemId, error.failure, error.recoveryUntil));
    } catch (_) {
      emit(_refused(itemId, ItemUseFailure.unknown, null));
    }
  }

  /// Prima di aprire un nuovo foglio: l'esito precedente non si rivede.
  void reset() {
    if (state is PotionDrinking) return;
    emit(const PotionIdle());
  }

  PotionRefused _refused(
    String itemId,
    ItemUseFailure failure,
    DateTime? recoveryUntil,
  ) => PotionRefused(
    itemId,
    failure,
    recoveryUntil: recoveryUntil,
    sequence: ++_refusals,
  );
}
