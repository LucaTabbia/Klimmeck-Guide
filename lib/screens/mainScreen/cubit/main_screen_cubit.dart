import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/models/city.dart';
import 'package:klimmeck_guide/repository/services/graphql/graphql.dart';

part 'main_screen_state.dart';

class MainScreenCubit extends Cubit<MainScreenState> {
  MainScreenCubit(this.graphQl) : super(MainScreenInitial());

  final KlimmeckGraphQl graphQl;

  Future<void> loadData() async {
    emit(MainScreenLoading());
    try {
      final cities = await graphQl.getCities();
      emit(MainScreenLoadData(cities));
    } catch (e) {
      emit(MainScreenError(e.toString()));
    }
  }
}
