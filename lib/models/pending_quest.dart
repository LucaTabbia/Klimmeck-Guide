import 'package:equatable/equatable.dart';
import 'package:klimmeck_guide/models/quest/quest.dart';

class PendingQuest extends Equatable {
  const PendingQuest({
    required this.id,
    required this.startDate,
    required this.waitingTime,
    required this.quest,
    this.pointsSpent,
  });

  final String id;

  /// Nullo mentre il personaggio viaggia verso il marker della quest (BE Phase 8 D-15).
  final DateTime? startDate;
  final int? waitingTime;
  final Quest? quest;
  final int? pointsSpent;

  factory PendingQuest.fromJson(Map<String, dynamic> json) => PendingQuest(
    id: json["id"],
    startDate: json["startDate"] != null
        ? DateTime.parse(json["startDate"])
        : null,
    waitingTime: json["waitingTime"] != null
        ? (json["waitingTime"] as num).toInt()
        : null,
    quest: json["quest"] != null ? Quest.fromJson(json["quest"]) : null,
    pointsSpent: (json["pointsSpent"] as num?)?.toInt(),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "startDate": startDate?.toIso8601String(),
    "waitingTime": waitingTime,
    "quest": quest?.id,
    "pointsSpent": pointsSpent,
  };

  PendingQuest copyWith({
    String? id,
    DateTime? startDate,
    int? waitingTime,
    Quest? quest,
    int? pointsSpent,
  }) {
    return PendingQuest(
      id: id ?? this.id,
      startDate: startDate ?? this.startDate,
      waitingTime: waitingTime ?? this.waitingTime,
      quest: quest ?? this.quest,
      pointsSpent: pointsSpent ?? this.pointsSpent,
    );
  }

  @override
  List<Object?> get props => [id, startDate, waitingTime, quest, pointsSpent];
}
