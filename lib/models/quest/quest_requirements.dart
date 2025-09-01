import '../enums/title_type.dart';
import '../equipment_quantity.dart';

class QuestRequirements {
  QuestRequirements({
    required this.requiredPoints,
    required this.requiredAdventurers,
    required this.recommendedLoot,
    required this.minTitle,
  });

  final int? requiredAdventurers;
  final List<AssetQuantity>? recommendedLoot;
  final int? requiredPoints;
  final TitleType? minTitle;

  factory QuestRequirements.fromJson(Map<String, dynamic> json) => QuestRequirements(
    requiredPoints: (json["requiredPoints"] as num?)?.toInt(),
    requiredAdventurers: (json["requiredAdventurers"] as num?)?.toInt(),
    recommendedLoot: json['recommendedLoot'] != null
        ? List<AssetQuantity>.from(json['recommendedLoot'].map((x) => AssetQuantity.fromJson(x)))
        : null,
    minTitle: json['minTitle'] != null ? TitleType.values.byName(json['minTitle']) : null,
  );

  Map<String, dynamic> toJson() => {
    "requiredPoints": requiredPoints,
    "requiredAdventurers": requiredAdventurers,
    "recommendedLoot": recommendedLoot,
    "minTitle": minTitle?.name,
  };
}
