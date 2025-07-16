import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/repository/storage/storage_manager.dart';
import '../../../../../models/user.dart';
import '../../../../../repository/services/api.dart';

part 'main_screen_state.dart';

class MainScreenCubit extends Cubit<MainScreenState> {
  MainScreenCubit(this.api) : super(MainScreenInitial());

  final Api api;

  Future<void> loadData() async {
    emit(MainScreenLoading());
    try {
      var customer = await KGStorageManager.getLoggedUser();
      if(customer != null){
        emit(MainScreenLoadData(customer));
      }else{
        emit(MainScreenError("no customer found"));
      }
    } catch (e) {
      print(e.toString());
      emit(MainScreenError(e.toString()));
    }
  }
}
