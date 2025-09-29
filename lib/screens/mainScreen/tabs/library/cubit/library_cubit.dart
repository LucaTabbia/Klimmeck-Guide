import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../models/lore.dart';
import '../../../../../repository/services/graphql/graphql.dart';

part 'library_state.dart';

class LibraryCubit extends Cubit<LibraryState> {
  LibraryCubit(this.graphQl) : super(LibraryInitial());

  final KlimmeckGraphQl graphQl;

  Future<void> loadLoreData() async {
    emit(LibraryLoading());
    try {
      final lores = await graphQl.getAllLores();

      emit(LibraryLoadData(lores));
    } catch (e) {
      print(e.toString());
      emit(LibraryError(e.toString()));
    }
  }

  Future<void> goToInitial() async {
    emit(LibraryInitial());
  }
}
