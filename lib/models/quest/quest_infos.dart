import 'package:equatable/equatable.dart';
import 'package:klimmeck_guide/models/pointOfInterest.dart';

import '../enemy.dart';
import '../enums/quest_type.dart';
import '../lore.dart';

class QuestInfos with EquatableMixin {
  const QuestInfos({
    required this.timeToComplete,
    required this.title,
    required this.enemy,
    required this.type,
    required this.markerLocation,
    required this.relatedLore,
  });

  final int? timeToComplete;
  final String? title;
  final Enemy? enemy;
  final QuestType? type;
  final PointOfInterest? markerLocation;
  final List<Lore>? relatedLore;

  factory QuestInfos.fromJson(Map<String, dynamic> json) {
    return QuestInfos(
      title: json["title"],
      enemy: json["enemy"] != null ? Enemy.fromJson(json["enemy"]) : null,
      type: json["type"] != null ? QuestType.values.byName(json["type"]) : null,
      markerLocation: json["markerLocation"] != null
          ? PointOfInterest.fromJson(json["markerLocation"])
          : null,
      relatedLore: json['relatedLore'] != null
          ? List<Lore>.from(json['relatedLore'].map((x) => Lore.fromJson(x)))
          : null,
      timeToComplete: (json["timeToComplete"] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
    "title": title,
    "enemy": enemy?.id,
    "type": type?.name,
    "markerLocation": markerLocation?.toJson(),
    "relatedLore": relatedLore?.map((s) => s.id).toList(),
    "timeToComplete": timeToComplete,
  };

  QuestInfos copyWith({
    int? timeToComplete,
    String? title,
    Enemy? enemy,
    QuestType? type,
    PointOfInterest? markerLocation,
    List<Lore>? relatedLore,
  }) {
    return QuestInfos(
      timeToComplete: timeToComplete ?? this.timeToComplete,
      title: title ?? this.title,
      enemy: enemy ?? this.enemy,
      type: type ?? this.type,
      markerLocation: markerLocation ?? this.markerLocation,
      relatedLore: relatedLore ?? this.relatedLore,
    );
  }

  @override
  List<Object?> get props => [
    timeToComplete,
    title,
    enemy,
    type,
    markerLocation,
    relatedLore,
  ];
}
