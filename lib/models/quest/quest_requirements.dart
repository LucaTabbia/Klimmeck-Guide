import 'package:equatable/equatable.dart';

import '../asset_quantity.dart';
import '../enums/title_type.dart';
import 'adventurer_slot.dart';

class QuestRequirements extends Equatable {
  const QuestRequirements({
    required this.requiredPoints,
    required this.requiredAdventurers,
    required this.recommendedLoot,
    required this.minTitle,
    this.hasRankSlots = false,
  });

  final List<AdventurerSlot> requiredAdventurers;
  final List<AssetQuantity>? recommendedLoot;
  final int? requiredPoints;
  final TitleType? minTitle;

  /// Vero solo se il BE ha inviato la forma Phase 8 (lista di slot): con la
  /// forma Phase 7 (`Int`) una capienza 0 non è un difetto di catalogo, decide
  /// il BE.
  final bool hasRankSlots;

  factory QuestRequirements.fromJson(Map<String, dynamic> json) =>
      QuestRequirements(
        requiredPoints: (json["requiredPoints"] as num?)?.toInt(),
        requiredAdventurers: AdventurerSlot.listFrom(
          json["requiredAdventurers"],
        ),
        recommendedLoot: json['recommendedLoot'] != null
            ? List<AssetQuantity>.from(
                json['recommendedLoot'].map((x) => AssetQuantity.fromJson(x)),
              )
            : null,
        minTitle: json['minTitle'] != null
            ? TitleType.values.byName(json['minTitle'])
            : null,
        hasRankSlots: json['requiredAdventurers'] is List,
      );

  Map<String, dynamic> toJson() => {
    "requiredPoints": requiredPoints,
    "requiredAdventurers": requiredAdventurers.map((s) => s.toJson()).toList(),
    "recommendedLoot": recommendedLoot,
    "minTitle": minTitle?.name,
  };

  QuestRequirements copyWith({
    List<AdventurerSlot>? requiredAdventurers,
    List<AssetQuantity>? recommendedLoot,
    int? requiredPoints,
    TitleType? minTitle,
    bool? hasRankSlots,
  }) {
    return QuestRequirements(
      requiredAdventurers: requiredAdventurers ?? this.requiredAdventurers,
      recommendedLoot: recommendedLoot ?? this.recommendedLoot,
      requiredPoints: requiredPoints ?? this.requiredPoints,
      minTitle: minTitle ?? this.minTitle,
      hasRankSlots: hasRankSlots ?? this.hasRankSlots,
    );
  }

  @override
  List<Object?> get props => [
    requiredAdventurers,
    recommendedLoot,
    requiredPoints,
    minTitle,
    hasRankSlots,
  ];
}
