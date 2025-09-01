import 'package:klimmeck_guide/models/asset_item.dart';

class AssetQuantity {
  AssetQuantity({required this.item, required this.quantity});

  final AssetItem? item;
  final int? quantity;

  factory AssetQuantity.fromJson(Map<String, dynamic> json) => AssetQuantity(
    item: json['item'] != null ? AssetItem.fromJson(json['item']) : null,
    quantity: json["quantity"] != null ? (json["quantity"] as num).toInt() : null,
  );

  Map<String, dynamic> toJson() => {"item": item?.toJson(), "quantity": quantity};
}
