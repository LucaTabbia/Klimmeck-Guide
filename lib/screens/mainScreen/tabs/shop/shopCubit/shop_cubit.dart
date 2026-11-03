import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/models/city_shop.dart';
import 'package:klimmeck_guide/shared/bloc/safe_emit.dart';

import '../../../../../repository/services/graphql/graphql.dart';

part 'shop_state.dart';

class ShopCubit extends Cubit<ShopState> with SafeEmit<ShopState> {
  ShopCubit(this.graphQl) : super(const ShopInitial());

  final KlimmeckGraphQl graphQl;

  /// Ultima città chiesta: le risposte di una città superata vengono scartate (D-03).
  String? _requestedCityId;

  Future<void> getData(String cityId) async {
    _requestedCityId = cityId;
    emit(ShopLoading(cityId));
    try {
      final pool = await graphQl.getCityShop(cityId);
      if (_requestedCityId != cityId) return;
      emit(ShopLoadData(pool));
    } on Object {
      if (_requestedCityId != cityId) return;
      emit(ShopError(cityId));
    }
  }
}
