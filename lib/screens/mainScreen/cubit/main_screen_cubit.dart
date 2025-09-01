import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/models/character/character.dart';
import 'package:klimmeck_guide/models/city.dart';
import 'package:klimmeck_guide/repository/storage/storage_manager.dart';

import '../../../models/quest/quest.dart';

part 'main_screen_state.dart';

class MainScreenCubit extends Cubit<MainScreenState> {
  MainScreenCubit() : super(MainScreenInitial());

  Future<void> loadData() async {
    emit(MainScreenLoading());
    try {
      final character = await KGStorageManager.getCharacter();
      final cities = await KGStorageManager.getAllCities();
      final quests = await KGStorageManager.getAllQuests();

      if (character != null && cities != null && quests != null) {
        emit(MainScreenLoadData(character, cities, quests));
      } else {
        emit(MainScreenError("Personaggio, missioni o città non presenti"));
      }
    } catch (e) {
      print(e.toString());
      emit(MainScreenError(e.toString()));
    }
  }
}
