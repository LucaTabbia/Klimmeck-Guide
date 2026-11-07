import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/models/city.dart';
import 'package:klimmeck_guide/repository/services/graphql/graphql.dart';
import 'package:klimmeck_guide/shared/bloc/safe_emit.dart';

part 'main_screen_state.dart';

class MainScreenCubit extends Cubit<MainScreenState>
    with SafeEmit<MainScreenState> {
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

  /// Rilettura silenziosa delle città (D-11): una città appena conosciuta
  /// riceve la sua lore senza riavvio; mai `MainScreenLoading` (il cold start),
  /// in errore resta la lista vecchia.
  Future<void> refreshCities() async {
    if (state is! MainScreenLoadData) return;
    try {
      final cities = await graphQl.getCities();
      final current = state;
      if (current is! MainScreenLoadData) return;
      if (listEquals(current.cities, cities)) return;
      emit(MainScreenLoadData(cities));
    } catch (e) {
      debugPrint('MainScreenCubit.refreshCities error: $e');
    }
  }
}
