import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/repository/innkeeper_failure.dart';
import 'package:klimmeck_guide/repository/innkeeper_repository.dart';
import 'package:klimmeck_guide/shared/bloc/safe_emit.dart';

part 'quest_generation_state.dart';

/// «Genera missioni» della Locanda (QGEN-03, D-08..D-10): una corsa del
/// generatore del BE alla volta; il FE non genera né filtra nulla (regola 4).
/// Vive con la route del pannello.
class QuestGenerationCubit extends Cubit<QuestGenerationState>
    with SafeEmit<QuestGenerationState> {
  QuestGenerationCubit({required InnkeeperRepository repository})
    : _repository = repository,
      super(const QuestGenerationIdle());

  final InnkeeperRepository _repository;
  int _failureSerial = 0;

  Future<void> generate() async {
    if (state is QuestGenerationSubmitting) return;
    emit(const QuestGenerationSubmitting());
    try {
      emit(
        QuestGenerationSucceeded(created: await _repository.generateQuests()),
      );
    } on InnkeeperException catch (error) {
      emit(
        QuestGenerationFailed(failure: error.failure, serial: ++_failureSerial),
      );
    }
  }
}
