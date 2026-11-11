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

  /// Confine di parsing (D-16): una voce il cui oggetto non si legge vale
  /// `null` e viene scartata dalla lista; il personaggio e il negozio restano.
  static AssetQuantity? tryFromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    try {
      return AssetQuantity.fromJson(json);
    } on Object {
      return null;
    }
  }

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
