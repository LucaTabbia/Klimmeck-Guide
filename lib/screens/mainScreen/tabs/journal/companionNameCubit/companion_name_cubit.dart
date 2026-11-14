import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/repository/companion_repository.dart';
import 'package:klimmeck_guide/repository/pet_rename_failure.dart';
import 'package:klimmeck_guide/shared/bloc/safe_emit.dart';

part 'companion_name_state.dart';

/// Nome del compagno (D-18, D-19): mai ottimistico, il nome arriva con
/// `characterUpdated`. Una sola richiesta in volo alla volta; il rifiuto si
/// mostra nel foglio del nome (D-31).
class CompanionNameCubit extends Cubit<CompanionNameState>
    with SafeEmit<CompanionNameState> {
  CompanionNameCubit(this._repository) : super(const CompanionNameIdle());

  final CompanionRepository _repository;
  int _sequence = 0;

  Future<void> rename({
    required String characterId,
    required String petId,
    required String name,
  }) async {
    if (isClosed || state is CompanionNameSubmitting) return;
    emit(CompanionNameSubmitting(petId));
    try {
      await _repository.rename(
        characterId: characterId,
        petId: petId,
        name: name,
      );
      emit(CompanionNameSaved(petId, sequence: ++_sequence));
    } on PetRenameException catch (error) {
      emit(_refused(petId, error.failure));
    } catch (_) {
      emit(_refused(petId, PetRenameFailure.unknown));
    }
  }

  /// Quando il giocatore riprova: il rifiuto precedente non si rivede.
  void reset() {
    if (state is CompanionNameSubmitting) return;
    emit(const CompanionNameIdle());
  }

  CompanionNameRefused _refused(String petId, PetRenameFailure failure) =>
      CompanionNameRefused(petId, failure, sequence: ++_sequence);
}
