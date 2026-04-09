import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/models/asset_quantity.dart';

import '../../../../../repository/services/graphql/graphql.dart';

part 'shop_state.dart';

class ShopCubit extends Cubit<ShopState> {
  ShopCubit(this.graphQl) : super(ShopInitial());

  final KlimmeckGraphQl graphQl;

  Future<void> getData() async {
    emit(ShopLoading());
    try {
      final equipments = await graphQl.getAllEquipmentAssetsQuantity(
        sellable: true,
      );
      final items = await graphQl.getAllLootAssetsQuantity();
      emit(ShopLoadData(equipments, items));
    } catch (e) {
      print(e.toString());
      emit(ShopError(e.toString()));
    }
  }
}
