import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/models/equipment.dart';

import '../../../../../repository/services/graphql/graphql.dart';

part 'journal_state.dart';

class JournalCubit extends Cubit<JournalState> {
  JournalCubit(this.graphQl) : super(JournalInitial());

  final KlimmeckGraphQl graphQl;

  Future<void> getData(String characterId) async {
    emit(JournalLoading());
    try {
      final equipment = await graphQl.getEquipment(characterId);
      emit(JournalLoadData(equipment));
    } catch (e) {
      print(e.toString());
      emit(JournalError(e.toString()));
    }
  }
}
