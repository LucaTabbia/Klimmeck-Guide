import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../storage_manager.dart';

part 'storage_state.dart';

class StorageCubit extends Cubit<StorageState> {
  StorageCubit() : super(StorageInitial());


  void saveShowOnBoarding(bool value) {
    KGStorageManager.saveShowOnBoarding(value);
    emit(StorageUpdated());
  }

  Future<void> updateFirebaseToken() async {
    String? token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      KGStorageManager.savePrimitivePreference("firebase_token", token);
      emit(StorageUpdated());
    } else {
      emit(StorageError());
    }
  }
}
