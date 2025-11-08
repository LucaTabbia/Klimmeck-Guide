import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/repository/services/graphql/graphql.dart';

import '../../../models/quest/quest.dart';

part 'quest_state.dart';

class QuestCubit extends Cubit<QuestState> {
  final KlimmeckGraphQl api;
  StreamSubscription<Quest>? _sub;

  QuestCubit(this.api) : super(QuestInitial());

  Future<void> loadQuest() async {
    emit(QuestLoading());
    try {
      final quests = await api.getQuests();
      emit(QuestLoaded(quests));
    } catch (e) {
      emit(QuestError(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
