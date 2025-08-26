import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/models/character.dart';
import 'package:klimmeck_guide/models/city.dart';
import 'package:klimmeck_guide/repository/storage/storage_manager.dart';

part 'main_screen_state.dart';

class MainScreenCubit extends Cubit<MainScreenState> {
  MainScreenCubit() : super(MainScreenInitial());

  Future<void> loadData() async {
    emit(MainScreenLoading());
    try {
      final character = await KGStorageManager.getCharacter();
      final cities = await KGStorageManager.getAllCities();

      if (character != null && cities != null) {
        emit(MainScreenLoadData(character, cities));
      } else {
        emit(MainScreenError("Personaggio o città non presenti"));
      }
    } catch (e) {
      print(e.toString());
      emit(MainScreenError(e.toString()));
    }
  }
}
