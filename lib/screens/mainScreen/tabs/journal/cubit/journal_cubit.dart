import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../models/equipment_item.dart';
import '../../../../../repository/storage/storage_manager.dart';

part 'journal_state.dart';

class JournalCubit extends Cubit<JournalState> {
  JournalCubit() : super(JournalInitial());

  Future<void> getData(List<String> ids) async {
    emit(JournalLoading());
    try {
      final lore = await KGStorageManager.getEquipmentItems(ids);

      if (lore != null) {
        emit(JournalLoadData(lore));
      } else {
        emit(JournalError("Personaggio o città non presenti"));
      }
    } catch (e) {
      print(e.toString());
      emit(JournalError(e.toString()));
    }
  }
}
