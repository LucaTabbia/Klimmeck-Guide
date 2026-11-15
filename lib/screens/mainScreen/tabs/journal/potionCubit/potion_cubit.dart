import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/models/use_item_result.dart';
import 'package:klimmeck_guide/repository/item_use_failure.dart';
import 'package:klimmeck_guide/repository/item_use_repository.dart';
import 'package:klimmeck_guide/shared/bloc/safe_emit.dart';

part 'potion_state.dart';

/// Bevuta di una pozione heal dal Diario (BE Phase 18, D-11), dal personaggio
/// o data a un compagno (D-07). Non è ottimistico: vita, scorta e ferite le
/// decide il backend e arrivano dal flusso del personaggio. L'avviso di un
/// rifiuto lo pubblica PotionOutcomeListener (un Cubit non chiama Cubit).
/// Una sola pozione in volo alla volta, bevuta o data.
class PotionCubit extends Cubit<PotionState> with SafeEmit<PotionState> {
  PotionCubit(this._repository) : super(const PotionIdle());

  final ItemUseRepository _repository;
  int _refusals = 0;

  Future<void> drink(String itemId) => _use(itemId);

  /// La pozione al compagno [petId]; [targetName] è il suo nome mostrato,
  /// usato dall'avviso di un rifiuto (D-20, D-32).
  Future<void> give(
    String itemId, {
    required String petId,
    required String targetName,
  }) => _use(itemId, targetPetId: petId, targetName: targetName);

  /// Prima di aprire un nuovo foglio: l'esito precedente non si rivede.
  void reset() {
    if (state is PotionDrinking) return;
    emit(const PotionIdle());
  }

  Future<void> _use(
    String itemId, {
    String? targetPetId,
    String? targetName,
  }) async {
    if (isClosed || state is PotionDrinking) return;
    emit(
      PotionDrinking(itemId, targetPetId: targetPetId, targetName: targetName),
    );
    try {
      final result = await _repository.useItem(itemId, petId: targetPetId);
      emit(
        PotionDrunk(
          itemId,
          result,
          targetPetId: targetPetId,
          targetName: targetName,
        ),
      );
    } on ItemUseException catch (error) {
      emit(_refused(itemId, error, targetPetId, targetName));
    } catch (_) {
      emit(
        _refused(
          itemId,
          const ItemUseException(ItemUseFailure.unknown),
          targetPetId,
          targetName,
        ),
      );
    }
  }

  PotionRefused _refused(
    String itemId,
    ItemUseException error,
    String? targetPetId,
    String? targetName,
  ) => PotionRefused(
    itemId,
    error.failure,
    recoveryUntil: error.recoveryUntil,
    sequence: ++_refusals,
    targetPetId: targetPetId,
    targetName: targetName,
  );
}
