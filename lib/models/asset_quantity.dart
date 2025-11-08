import 'package:equatable/equatable.dart';
import 'package:klimmeck_guide/models/asset_item.dart';

class AssetQuantity extends Equatable {
  const AssetQuantity({required this.item, required this.quantity});
  final AssetItem? item;
  final int? quantity;

  factory AssetQuantity.fromJson(Map<String, dynamic> json) => AssetQuantity(
    item: json['item'] != null ? AssetItem.fromJson(json['item']) : null,
    quantity: json["quantity"] != null
        ? (json["quantity"] as num).toInt()
        : null,
  );

  Map<String, dynamic> toJson() => {
    "item": item?.toJson(),
    "quantity": quantity,
  };

  AssetQuantity copyWith({AssetItem? item, int? quantity}) {
    return AssetQuantity(
      item: item ?? this.item,
      quantity: quantity ?? this.quantity,
    );
  }

  @override
  List<Object?> get props => [item, quantity];
}

class AssetQuantityInput {
  AssetQuantityInput({required this.item, required this.quantity});

  final String item;
  int quantity;

  Map<String, dynamic> toJson() => {"item": item, "quantity": quantity};
}
