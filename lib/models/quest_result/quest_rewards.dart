import 'package:equatable/equatable.dart';
import 'package:klimmeck_guide/models/asset_quantity.dart';
import 'package:klimmeck_guide/models/coins.dart';
import 'package:klimmeck_guide/models/pet.dart';
import 'package:klimmeck_guide/models/quest_result/quest_result.dart';

/// Ricompense di una quest risolta: monete, oggetti (orfani esclusi) e compagno.
class QuestRewards extends Equatable {
  const QuestRewards({required this.coins, required this.items, this.pet});

  final Coins coins;
  final List<AssetQuantity> items;

  /// Compagno ottenuto (BE Phase 13 D-21, D-07).
  final Pet? pet;

  bool get isEmpty => coins.toCopper() == 0 && items.isEmpty && pet == null;

  factory QuestRewards.fromJson(Map<String, dynamic> json) => QuestRewards(
    coins: Coins.fromJson(json['coins'] as Map<String, dynamic>),
    items: QuestResult.assetQuantitiesFrom(json['items']),
    pet: Pet.tryFromJson(json['pet']),
  );

  Map<String, dynamic> toJson() => {
    'coins': coins.toJson(),
    'items': items.map((entry) => entry.toJson()).toList(),
    if (pet != null) 'pet': {'id': pet!.id, 'name': pet!.name},
  };

  @override
  List<Object?> get props => [coins, items, pet];
}
