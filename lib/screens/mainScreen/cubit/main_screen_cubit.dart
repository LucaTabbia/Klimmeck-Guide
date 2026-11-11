import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/models/city.dart';
import 'package:klimmeck_guide/repository/services/graphql/graphql.dart';
import 'package:klimmeck_guide/shared/bloc/safe_emit.dart';
import 'package:klimmeck_guide/utils/app_log.dart';

part 'main_screen_state.dart';

class MainScreenCubit extends Cubit<MainScreenState>
    with SafeEmit<MainScreenState> {
  MainScreenCubit(this.graphQl) : super(MainScreenInitial());

  final KlimmeckGraphQl graphQl;

  bool _isRefreshing = false;
  bool _hasPendingRefresh = false;

  Future<void> loadData() async {
    emit(MainScreenLoading());
    try {
      final cities = await graphQl.getCities();
      emit(MainScreenLoadData(cities));
    } catch (e) {
      _hasPendingRefresh = false;
      emit(MainScreenError(e.toString()));
      return;
    }
    if (_hasPendingRefresh) await _runRefreshLoop();
  }

  /// Rilettura silenziosa delle città (D-11): una città appena conosciuta
  /// riceve la sua lore senza riavvio; mai `MainScreenLoading` (il cold start),
  /// in errore resta la lista vecchia. Una sola lettura alla volta, con una
  /// sola rilettura in coda; chiesta durante il cold start, parte dopo.
  Future<void> refreshCities() async {
    if (state is MainScreenLoading || _isRefreshing) {
      _hasPendingRefresh = true;
      return;
    }
    if (state is! MainScreenLoadData) return;
    await _runRefreshLoop();
  }

  Future<void> _runRefreshLoop() async {
    _isRefreshing = true;
    try {
      do {
        _hasPendingRefresh = false;
        await _readCities();
      } while (_hasPendingRefresh && state is MainScreenLoadData);
    } finally {
      _isRefreshing = false;
    }
  }

  Future<void> _readCities() async {
    try {
      final cities = await graphQl.getCities();
      final current = state;
      if (current is! MainScreenLoadData) return;
      if (listEquals(current.cities, cities)) return;
      emit(MainScreenLoadData(cities));
    } catch (e) {
      appLog('MainScreenCubit.refreshCities error: ${e.runtimeType}');
    }
  }
}
