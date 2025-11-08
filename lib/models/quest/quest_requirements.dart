import 'package:equatable/equatable.dart';

import '../asset_quantity.dart';
import '../enums/title_type.dart';

class QuestRequirements extends Equatable {
  const QuestRequirements({
    required this.requiredPoints,
    required this.requiredAdventurers,
    required this.recommendedLoot,
    required this.minTitle,
  });

  final int? requiredAdventurers;
  final List<AssetQuantity>? recommendedLoot;
  final int? requiredPoints;
  final TitleType? minTitle;

  factory QuestRequirements.fromJson(Map<String, dynamic> json) =>
      QuestRequirements(
        requiredPoints: (json["requiredPoints"] as num?)?.toInt(),
        requiredAdventurers: (json["requiredAdventurers"] as num?)?.toInt(),
        recommendedLoot: json['recommendedLoot'] != null
            ? List<AssetQuantity>.from(
                json['recommendedLoot'].map((x) => AssetQuantity.fromJson(x)),
              )
            : null,
        minTitle: json['minTitle'] != null
            ? TitleType.values.byName(json['minTitle'])
            : null,
      );

  Map<String, dynamic> toJson() => {
    "requiredPoints": requiredPoints,
    "requiredAdventurers": requiredAdventurers,
    "recommendedLoot": recommendedLoot,
    "minTitle": minTitle?.name,
  };

  QuestRequirements copyWith({
    int? requiredAdventurers,
    List<AssetQuantity>? recommendedLoot,
    int? requiredPoints,
    TitleType? minTitle,
  }) {
    return QuestRequirements(
      requiredAdventurers: requiredAdventurers ?? this.requiredAdventurers,
      recommendedLoot: recommendedLoot ?? this.recommendedLoot,
      requiredPoints: requiredPoints ?? this.requiredPoints,
      minTitle: minTitle ?? this.minTitle,
    );
  }

  @override
  List<Object?> get props => [
    requiredAdventurers,
    recommendedLoot,
    requiredPoints,
    minTitle,
  ];
}
