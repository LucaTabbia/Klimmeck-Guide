import 'package:klimmeck_guide/models/asset_quantity.dart';
import 'package:klimmeck_guide/models/coins.dart';

Coins getTotalAmount(List<AssetQuantity> items, bool isBuy) {
  Coins total = Coins();

  for (final item in items) {
    final price = isBuy ? item.item?.buyPrice : item.item?.sellPrice;
    if (price == null) continue;

    total += price.multiply(item.quantity ?? 0);
  }

  return total;
}
