import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/models/loot_item.dart';

import '../../../../../models/equipment_item.dart';
import '../../../../../repository/services/graphql/graphql.dart';

part 'shop_state.dart';

class ShopCubit extends Cubit<ShopState> {
  ShopCubit(this.graphQl) : super(ShopInitial());

  final KlimmeckGraphQl graphQl;

  Future<void> getData() async {
    emit(ShopLoading());
    try {
      final equipments = await graphQl.getAllEquipmentItems();
      final items = await graphQl.getAllLootItems();
      emit(ShopLoadData(equipments, items));
    } catch (e) {
      print(e.toString());
      emit(ShopError(e.toString()));
    }
  }
}
