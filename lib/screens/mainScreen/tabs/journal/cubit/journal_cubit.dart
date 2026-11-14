import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/models/request/equip_item_request.dart';
import 'package:klimmeck_guide/repository/equipment_failure.dart';
import 'package:klimmeck_guide/repository/equipment_repository.dart';
import 'package:klimmeck_guide/shared/bloc/safe_emit.dart';

part 'journal_state.dart';

class JournalCubit extends Cubit<JournalState> with SafeEmit<JournalState> {
  JournalCubit(this._repository) : super(const JournalIdle());

  final EquipmentRepository _repository;
  int _sequence = 0;

  Future<void> equipItem(EquipItemRequest request) async {
    try {
      await _repository.equip(request);
    } on EquipmentException catch (error) {
      emit(JournalEquipRefused(failure: error.failure, sequence: ++_sequence));
    }
  }
}
