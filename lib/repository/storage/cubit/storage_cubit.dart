import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'storage_state.dart';

class StorageCubit extends Cubit<StorageState> {
  StorageCubit() : super(StorageInitial());
}
