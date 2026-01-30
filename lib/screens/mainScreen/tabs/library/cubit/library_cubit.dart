import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../models/lore.dart';
import '../../../../../repository/services/graphql/graphql.dart';

part 'library_state.dart';

class LibraryCubit extends Cubit<LibraryState> {
  LibraryCubit(this.graphQl) : super(const LibraryInitial());

  final KlimmeckGraphQl graphQl;

  Future<void> loadLoreData() async {
    emit(const LibraryLoading());
    try {
      final lores = await graphQl.getAllLores();
      emit(LibraryLoadData(lores));
    } catch (e) {
      debugPrint('LibraryCubit.loadLoreData error: $e');
      emit(LibraryError(e.toString()));
    }
  }

  void goToInitial() {
    emit(const LibraryInitial());
  }
}
