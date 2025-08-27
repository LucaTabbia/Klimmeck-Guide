import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/models/enums/lore_type.dart';

import '../../../../../models/lore.dart';
import '../../../../../repository/storage/storage_manager.dart';

part 'library_state.dart';

class LibraryCubit extends Cubit<LibraryState> {
  LibraryCubit() : super(LibraryInitial());

  Future<void> loadLoreData(List<LoreType> types) async {
    emit(LibraryLoading());
    try {
      final lore = await KGStorageManager.getLoreByTypes(types);

      if (lore != null) {
        emit(LibraryLoadData(lore));
      } else {
        emit(LibraryError("Lore non caricate"));
      }
    } catch (e) {
      print(e.toString());
      emit(LibraryError(e.toString()));
    }
  }

  Future<void> goToInitial() async {
    emit(LibraryInitial());
  }
}
