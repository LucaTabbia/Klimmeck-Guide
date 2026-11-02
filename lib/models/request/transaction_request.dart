import 'package:klimmeck_guide/models/asset_quantity.dart';

import '../coins.dart';

class TransactionRequest {
  TransactionRequest({
    required this.id,
    required this.boughtItems,
    required this.soldItems,
    required this.isTotalPositive,
    required this.total,
  });

  final String id;
  final TransactionItems boughtItems;
  final TransactionItems soldItems;
  final bool isTotalPositive;
  final Coins total;

  Map<String, dynamic> toJson() => {
    "id": id,
    "boughtItems": boughtItems.toJson(),
    "soldItems": soldItems.toJson(),
    "isTotalPositive": isTotalPositive,
    "total": total.toJson(),
  };
}

class TransactionItems {
  TransactionItems({
    required this.equipAssets,
    required this.lootAssets,
    this.petAssets = const [],
  });

  final List<AssetQuantityInput> equipAssets;
  final List<AssetQuantityInput> lootAssets;

  /// Compagni scambiati: quantità sempre 1 (BE D-17, D-07).
  final List<AssetQuantityInput> petAssets;

  Map<String, dynamic> toJson() => {
    'equipAssets': equipAssets.map((a) => a.toJson()).toList(),
    'lootAssets': lootAssets.map((a) => a.toJson()).toList(),
    'petAssets': petAssets.map((a) => a.toJson()).toList(),
  };
}
