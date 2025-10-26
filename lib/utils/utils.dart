import 'package:klimmeck_guide/models/asset_quantity.dart';
import 'package:klimmeck_guide/models/coins.dart';

String getStringToShowFromDuration(Duration duration) {
  return "${duration.inHours != 0 ? "${duration.inHours} ore" : ""} ${duration.inMinutes.remainder(60) != 0 ? ", ${duration.inMinutes.remainder(60)} minuti" : ""} ${duration.inSeconds.remainder(60) != 0 ? ", ${duration.inSeconds.remainder(60)} secondi" : ""}";
}

Coins getTotalAmount(List<AssetQuantity> items, bool isBuy) {
  Coins total = Coins();

  for (final item in items) {
    final price = isBuy ? item.item?.buyPrice : item.item?.sellPrice;
    if (price == null) continue;

    total += price.multiply(item.quantity ?? 0);
  }

  return total;
}
