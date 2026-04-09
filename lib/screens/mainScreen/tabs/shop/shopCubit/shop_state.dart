part of 'shop_cubit.dart';

@immutable
abstract class ShopState extends Equatable {
  const ShopState();

  @override
  List<Object?> get props => [];
}

class ShopInitial extends ShopState {}

class ShopLoadData extends ShopState {
  final List<AssetQuantity> equipmentItems;
  final List<AssetQuantity> lootItems;

  const ShopLoadData(this.equipmentItems, this.lootItems);

  @override
  List<Object?> get props => [equipmentItems, lootItems];
}

class ShopLoading extends ShopState {}

class ShopError extends ShopState {
  final String errorMessage;

  const ShopError(this.errorMessage);

  @override
  List<Object?> get props => [errorMessage];
}
