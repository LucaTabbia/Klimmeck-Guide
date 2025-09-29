import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/models/character/character.dart';
import 'package:klimmeck_guide/models/city.dart';
import 'package:klimmeck_guide/repository/services/graphql/graphql.dart';

import '../../../models/quest/quest.dart';

part 'main_screen_state.dart';

class MainScreenCubit extends Cubit<MainScreenState> {
  MainScreenCubit(this.graphQl) : super(MainScreenInitial());

  final KlimmeckGraphQl graphQl;

  Future<void> loadData() async {
    emit(MainScreenLoading());
    try {
      final character = await graphQl.getCharacter("68c191de541d89c481b8322b");
      final cities = await graphQl.getCities();
      final quests = await graphQl.getQuests();
      emit(MainScreenLoadData(character, cities, quests));
    } catch (e) {
      emit(MainScreenError(e.toString()));
    }
  }
}
