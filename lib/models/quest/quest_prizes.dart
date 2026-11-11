import 'package:equatable/equatable.dart';
import 'package:klimmeck_guide/models/asset_item.dart';
import 'package:klimmeck_guide/models/pet.dart';
import 'package:klimmeck_guide/models/quest/quest_cure.dart';

import '../asset_quantity.dart';
import '../coins.dart';

class QuestPrizes extends Equatable {
  const QuestPrizes({
    required this.prizeCoins,
    required this.prizeItem,
    required this.xpPrize,
    required this.randomLoot,
    this.pet,
    this.cure,
  });

  final List<AssetQuantity>? randomLoot;
  final Coins? prizeCoins;
  final int? xpPrize;
  final AssetItem? prizeItem;

  /// Compagno in premio (BE Phase 13 D-21): solo sui boss, raro (D-06).
  final Pet? pet;

  /// Cura della quest (BE Phase 18, D-01); `null` = la quest non cura nulla.
  final QuestCure? cure;

  factory QuestPrizes.fromJson(Map<String, dynamic> json) => QuestPrizes(
    prizeCoins: json["prizeCoins"] != null
        ? Coins.fromJson(json["prizeCoins"])
        : null,
    xpPrize: (json["xpPrize"] as num?)?.toInt(),
    prizeItem: _prizeItemFrom(json['prizeItem']),
    randomLoot: json['randomLoot'] != null
        ? List<AssetQuantity>.from(
            json['randomLoot'].map((x) => AssetQuantity.fromJson(x)),
          )
        : null,
    pet: Pet.tryFromJson(json['pet']),
    cure: QuestCure.tryFromJson(json['cure']),
  );

  Map<String, dynamic> toJson() => {
    "prizeCoins": prizeCoins?.toJson(),
    "xpPrize": xpPrize,
    "prizeItem": prizeItem?.toJson(),
    "randomLoot": randomLoot,
    "pet": pet?.id,
    "cure": cure?.toJson(),
  };

  QuestPrizes copyWith({
    List<AssetQuantity>? randomLoot,
    Coins? prizeCoins,
    int? xpPrize,
    AssetItem? prizeItem,
    Pet? pet,
    QuestCure? cure,
  }) {
    return QuestPrizes(
      randomLoot: randomLoot ?? this.randomLoot,
      prizeCoins: prizeCoins ?? this.prizeCoins,
      xpPrize: xpPrize ?? this.xpPrize,
      prizeItem: prizeItem ?? this.prizeItem,
      pet: pet ?? this.pet,
      cure: cure ?? this.cure,
    );
  }

  @override
  List<Object?> get props => [
    randomLoot,
    prizeCoins,
    xpPrize,
    prizeItem,
    pet,
    cure,
  ];
}

/// Sul filo `prizeItem` è un `AssetQuantity { quantity item }` (SDL BE);
/// la forma nuda dell'item resta accettata per compatibilità.
AssetItem? _prizeItemFrom(Object? json) {
  if (json is! Map<String, dynamic>) return null;
  final item = json.containsKey('item') ? json['item'] : json;
  if (item is! Map<String, dynamic>) return null;
  return AssetItem.fromJson(item);
}
