import 'package:equatable/equatable.dart';
import 'package:klimmeck_guide/models/asset_quantity.dart';
import 'package:klimmeck_guide/models/city_shop.dart';
import 'package:klimmeck_guide/models/coins.dart';
import 'package:klimmeck_guide/models/equipment_item.dart';
import 'package:klimmeck_guide/models/pet.dart';
import 'package:klimmeck_guide/models/request/transaction_request.dart';
import 'package:klimmeck_guide/utils/utils.dart';

/// Selezione di un lato del negozio (acquisto o vendita): quantità di
/// equipaggiamento/oggetti e compagni, sempre uno per tipo (D-07, D-15).
class TradeSelection extends Equatable {
  const TradeSelection({this.assets = const [], this.pets = const []});

  final List<AssetQuantity> assets;
  final List<Pet> pets;

  bool get isEmpty => assets.isEmpty && pets.isEmpty;

  bool containsPet(String petId) => pets.any((pet) => pet.id == petId);

  Coins total({required bool isBuy}) => pets.fold(
    getTotalAmount(assets, isBuy),
    (sum, pet) =>
        sum + ((isBuy ? pet.buyPrice : pet.sellPrice) ?? const Coins()),
  );

  TradeSelection withAssets(List<AssetQuantity> assets) =>
      TradeSelection(assets: List.unmodifiable(assets), pets: pets);

  TradeSelection addPet(Pet pet) => containsPet(pet.id)
      ? this
      : TradeSelection(assets: assets, pets: List.unmodifiable([...pets, pet]));

  TradeSelection removePet(String petId) => TradeSelection(
    assets: assets,
    pets: List.unmodifiable(pets.where((pet) => pet.id != petId)),
  );

  /// Dopo un nuovo pool l'acquisto tiene solo ciò che la città vende ancora (D-03).
  TradeSelection retainPurchasable(CityShop pool) {
    final soldIds = {
      for (final asset in [...pool.equipment, ...pool.loot])
        if (asset.item?.id case final id?) id,
    };
    final petIds = {for (final pet in pool.pets) pet.id};
    return TradeSelection(
      assets: List.unmodifiable(
        assets.where((asset) => soldIds.contains(asset.item?.id)),
      ),
      pets: List.unmodifiable(pets.where((pet) => petIds.contains(pet.id))),
    );
  }

  TransactionItems toTransactionItems() {
    final equipAssets = <AssetQuantityInput>[];
    final lootAssets = <AssetQuantityInput>[];
    for (final asset in assets) {
      final itemId = asset.item?.id;
      if (itemId == null) continue;
      final input = AssetQuantityInput(
        item: itemId,
        quantity: asset.quantity ?? 0,
      );
      if (asset.item is EquipmentItem) {
        equipAssets.add(input);
      } else {
        lootAssets.add(input);
      }
    }
    return TransactionItems(
      equipAssets: equipAssets,
      lootAssets: lootAssets,
      petAssets: [
        for (final pet in pets) AssetQuantityInput(item: pet.id, quantity: 1),
      ],
    );
  }

  @override
  List<Object?> get props => [assets, pets];
}

/// Compagni acquistabili: il pool meno quelli già posseduti (D-08); nessun
/// altro filtro (regola 4).
List<Pet> purchasablePets(List<Pet> pool, List<Pet> owned) {
  final ownedIds = {for (final pet in owned) pet.id};
  return List.unmodifiable(pool.where((pet) => !ownedIds.contains(pet.id)));
}

/// Richiesta di `doTransaction` dalle due selezioni (D-07): i compagni
/// comprati viaggiano solo nell'acquisto, quelli venduti solo nella vendita;
/// comprare non equipaggia mai (D-08).
TransactionRequest buildTransactionRequest({
  required String characterId,
  required TradeSelection bought,
  required TradeSelection sold,
  required Coins total,
  required bool isTotalPositive,
}) => TransactionRequest(
  id: characterId,
  boughtItems: bought.toTransactionItems(),
  soldItems: sold.toTransactionItems(),
  isTotalPositive: isTotalPositive,
  total: total,
);
