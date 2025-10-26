part of 'shop_cubit.dart';

@immutable
abstract class ShopState {}

class ShopInitial extends ShopState {}

class ShopLoadData extends ShopState {
  final List<AssetQuantity> equipmentItems;
  final List<AssetQuantity> lootItems;

  ShopLoadData(this.equipmentItems, this.lootItems);
}

class ShopLoading extends ShopState {}

class ShopError extends ShopState {
  final String errorMessage;

  ShopError(this.errorMessage);
}
