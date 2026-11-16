import 'package:equatable/equatable.dart';
import 'package:klimmeck_guide/models/point_of_interest.dart';

import '../enums/quest_type.dart';
import '../lore.dart';
import 'quest_enemy.dart';

class QuestInfos with EquatableMixin {
  const QuestInfos({
    required this.timeToComplete,
    required this.title,
    required this.type,
    required this.markerLocation,
    required this.relatedLore,
    this.enemies = const [],
    this.description,
  });

  final int? timeToComplete;
  final String? title;
  final QuestType? type;
  final PointOfInterest? markerLocation;
  final List<Lore>? relatedLore;

  /// Nemici della quest con le quantità, nell'ordine del BE (D-01, D-02).
  final List<QuestEnemy> enemies;

  /// Annuncio della quest nella voce del committente (BE Phase 11 D-32, D-05).
  final String? description;

  factory QuestInfos.fromJson(Map<String, dynamic> json) {
    return QuestInfos(
      title: json["title"],
      type: _typeOf(json["type"]),
      markerLocation: json["markerLocation"] != null
          ? PointOfInterest.fromJson(json["markerLocation"])
          : null,
      relatedLore: json['relatedLore'] != null
          ? List<Lore>.from(json['relatedLore'].map((x) => Lore.fromJson(x)))
          : null,
      timeToComplete: (json["timeToComplete"] as num?)?.toInt(),
      enemies: QuestEnemy.listFrom(json["enemies"]),
      description: json["description"] as String?,
    );
  }

  /// Tipo ignoto = quest illeggibile: la scarta `Quest.tryFromJson`.
  static QuestType? _typeOf(Object? wire) {
    if (wire == null) return null;
    return QuestType.fromWire(wire) ??
        (throw ArgumentError.value(wire, 'type', 'unknown quest type'));
  }

  Map<String, dynamic> toJson() => {
    "title": title,
    "type": type?.wireName,
    "markerLocation": markerLocation?.toJson(),
    "relatedLore": relatedLore?.map((s) => s.id).toList(),
    "timeToComplete": timeToComplete,
    "enemies": enemies.map((e) => e.toJson()).toList(),
    "description": description,
  };

  QuestInfos copyWith({
    int? timeToComplete,
    String? title,
    QuestType? type,
    PointOfInterest? markerLocation,
    List<Lore>? relatedLore,
    List<QuestEnemy>? enemies,
    String? description,
  }) {
    return QuestInfos(
      timeToComplete: timeToComplete ?? this.timeToComplete,
      title: title ?? this.title,
      type: type ?? this.type,
      markerLocation: markerLocation ?? this.markerLocation,
      relatedLore: relatedLore ?? this.relatedLore,
      enemies: enemies ?? this.enemies,
      description: description ?? this.description,
    );
  }

  @override
  List<Object?> get props => [
    timeToComplete,
    title,
    type,
    markerLocation,
    relatedLore,
    enemies,
    description,
  ];
}
