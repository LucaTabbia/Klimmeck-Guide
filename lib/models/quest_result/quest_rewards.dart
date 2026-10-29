import 'package:equatable/equatable.dart';
import 'package:klimmeck_guide/models/asset_quantity.dart';
import 'package:klimmeck_guide/models/coins.dart';
import 'package:klimmeck_guide/models/quest_result/quest_result.dart';

/// Ricompense di una quest risolta: monete e oggetti (orfani esclusi).
class QuestRewards extends Equatable {
  const QuestRewards({required this.coins, required this.items});

  final Coins coins;
  final List<AssetQuantity> items;

  bool get isEmpty => coins.toCopper() == 0 && items.isEmpty;

  factory QuestRewards.fromJson(Map<String, dynamic> json) => QuestRewards(
    coins: Coins.fromJson(json['coins'] as Map<String, dynamic>),
    items: QuestResult.assetQuantitiesFrom(json['items']),
  );

  Map<String, dynamic> toJson() => {
    'coins': coins.toJson(),
    'items': items.map((entry) => entry.toJson()).toList(),
  };

  @override
  List<Object?> get props => [coins, items];
}
