import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/repository/quest_board_repository.dart';
import 'package:klimmeck_guide/shared/bloc/safe_emit.dart';

import '../../../models/quest/quest.dart';

part 'quest_state.dart';

class QuestCubit extends Cubit<QuestState> with SafeEmit<QuestState> {
  final QuestBoardRepository repository;
  StreamSubscription<Quest>? _sub;
  int _refreshGeneration = 0;

  QuestCubit(this.repository) : super(QuestInitial());

  Future<void> loadQuest() async {
    emit(QuestLoading());
    try {
      final quests = await repository.getQuests();
      final current = state is QuestLoaded ? state as QuestLoaded : null;
      emit(
        QuestLoaded(
          quests,
          cityId: current?.cityId,
          cityPointIds: current?.cityPointIds,
        ),
      );
    } catch (e) {
      emit(QuestError(e.toString()));
    }
  }

  /// Rilettura silenziosa (D-20 C5): mai QuestLoading, i dati precedenti restano
  /// su errore; l'ultima chiamata vince. La Board la chiama all'apertura e dopo un
  /// rifiuto che rende stantia la lista.
  Future<void> refreshQuests({String? cityId}) async {
    final generation = ++_refreshGeneration;
    final previous = state is QuestLoaded ? state as QuestLoaded : null;
    final results = await Future.wait([
      _attempt(repository.getQuests),
      cityId == null
          ? Future<Object?>.value()
          : _attempt(() => repository.getCityPointIds(cityId)),
    ]);
    if (isClosed || generation != _refreshGeneration) return;
    final quests = results[0] as List<Quest>? ?? previous?.quests;
    if (quests == null) return;
    final keepsCity = cityId == null || cityId == previous?.cityId;
    final cityPointIds =
        results[1] as Set<String>? ??
        (keepsCity ? previous?.cityPointIds : null);
    final next = QuestLoaded(
      quests,
      cityId: cityId ?? previous?.cityId,
      cityPointIds: cityPointIds,
    );
    if (next != previous) emit(next);
  }

  Future<Object?> _attempt(Future<Object?> Function() call) async {
    try {
      return await call();
    } catch (error) {
      debugPrint('Quest refresh failed (${error.runtimeType})');
      return null;
    }
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
