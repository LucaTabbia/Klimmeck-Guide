import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/models/equipment.dart';
import 'package:klimmeck_guide/models/request/equip_item_request.dart';

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

  Future<void> equipItem(EquipItemRequest request) async {
    try {
      await graphQl.equipItem(request);
    } catch (e) {
      print(e.toString());
      emit(JournalError(e.toString()));
    }
  }
}
