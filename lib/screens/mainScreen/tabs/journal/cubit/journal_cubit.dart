import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/models/equipment.dart';
import 'package:klimmeck_guide/models/loot_item.dart';

import '../../../../../models/equipment_item.dart';
import '../../../../../repository/services/graphql/graphql.dart';

part 'journal_state.dart';

class JournalCubit extends Cubit<JournalState> {
  JournalCubit(this.graphQl) : super(JournalInitial());

  final KlimmeckGraphQl graphQl;

  Future<void> getData(List<String> equipIds, List<String> itemIds, String characterId) async {
    emit(JournalLoading());
    try {
      List<EquipmentItem> equipments = [];
      if (equipIds.isNotEmpty) {
        equipments = await graphQl.getEquipmentItems(equipIds);
      }
      List<LootItem> items = [];
      if (itemIds.isNotEmpty) {
        items = await graphQl.getLootItems(itemIds);
      }
      final equipment = await graphQl.getEquipment(characterId);
      emit(JournalLoadData(equipments, items, equipment));
    } catch (e) {
      print(e.toString());
      emit(JournalError(e.toString()));
    }
  }
}
