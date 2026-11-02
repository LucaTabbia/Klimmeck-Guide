part of 'shop_cubit.dart';

abstract class ShopState extends Equatable {
  const ShopState();

  @override
  List<Object?> get props => [];
}

class ShopInitial extends ShopState {
  const ShopInitial();
}

class ShopLoading extends ShopState {
  const ShopLoading(this.cityId);

  final String cityId;

  @override
  List<Object?> get props => [cityId];
}

/// Pool della città [cityId] (D-01): la pagina lo mostra solo se è ancora la
/// città del marker (il cubit vive a livello di shell, D-03).
class ShopLoadData extends ShopState {
  const ShopLoadData(this.pool);

  final CityShop pool;

  String get cityId => pool.cityId;

  @override
  List<Object?> get props => [pool];
}

/// Nessun testo grezzo: la pagina resta usabile (la vendita funziona comunque).
class ShopError extends ShopState {
  const ShopError(this.cityId);

  final String cityId;

  @override
  List<Object?> get props => [cityId];
}
