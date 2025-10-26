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

  String id;
  TransactionItems boughtItems;
  TransactionItems soldItems;
  bool isTotalPositive;
  Coins total;

  Map<String, dynamic> toJson() => {
    "id": id,
    "boughtItems": boughtItems.toJson(),
    "soldItems": soldItems.toJson(),
    "isTotalPositive": isTotalPositive,
    "total": total.toJson(),
  };
}

class TransactionItems {
  TransactionItems({required this.equipAssets, required this.lootAssets});

  List<AssetQuantityInput> lootAssets;
  List<AssetQuantityInput> equipAssets;

  Map<String, dynamic> toJson() => {
    "lootAssets": lootAssets,
    "equipAssets": equipAssets,
  };
}
