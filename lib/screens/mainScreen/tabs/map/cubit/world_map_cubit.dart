import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../models/lore.dart';
import '../../../../../repository/storage/storage_manager.dart';

part 'world_map_state.dart';

class WorldMapCubit extends Cubit<WorldMapState> {
  WorldMapCubit() : super(WorldMapInitial());

  Future<void> loadLoreData(String id) async {
    emit(WorldMapLoading());
    try {
      final lore = await KGStorageManager.getLoreById(id);

      if (lore != null) {
        emit(WorldMapLoadData(lore));
      } else {
        emit(WorldMapError("Personaggio o città non presenti"));
      }
    } catch (e) {
      print(e.toString());
      emit(WorldMapError(e.toString()));
    }
  }
}
