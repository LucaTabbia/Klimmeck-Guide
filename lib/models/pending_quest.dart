import 'package:equatable/equatable.dart';
import 'package:klimmeck_guide/models/quest/quest.dart';

class PendingQuest extends Equatable {
  const PendingQuest({
    required this.id,
    required this.startDate,
    required this.waitingTime,
    required this.quest,
    this.pointsSpent,
    this.arrivedAt,
  });

  final String id;

  /// Nullo mentre il personaggio viaggia verso il marker della quest (BE Phase 8 D-15).
  final DateTime? startDate;

  /// Arrivo sul marker (BE Phase 9, 09-19): `startDate` resta nullo finché il
  /// gruppo non è al completo.
  final DateTime? arrivedAt;
  final int? waitingTime;
  final Quest? quest;
  final int? pointsSpent;

  bool get isTravelling => startDate == null && arrivedAt == null;

  bool get isWaitingForParty => startDate == null && arrivedAt != null;

  factory PendingQuest.fromJson(Map<String, dynamic> json) => PendingQuest(
    id: json["id"],
    startDate: json["startDate"] != null
        ? DateTime.parse(json["startDate"])
        : null,
    arrivedAt: json["arrivedAt"] != null
        ? DateTime.parse(json["arrivedAt"])
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
    "arrivedAt": arrivedAt?.toIso8601String(),
    "waitingTime": waitingTime,
    "quest": quest?.id,
    "pointsSpent": pointsSpent,
  };

  PendingQuest copyWith({
    String? id,
    DateTime? startDate,
    DateTime? arrivedAt,
    int? waitingTime,
    Quest? quest,
    int? pointsSpent,
  }) {
    return PendingQuest(
      id: id ?? this.id,
      startDate: startDate ?? this.startDate,
      arrivedAt: arrivedAt ?? this.arrivedAt,
      waitingTime: waitingTime ?? this.waitingTime,
      quest: quest ?? this.quest,
      pointsSpent: pointsSpent ?? this.pointsSpent,
    );
  }

  @override
  List<Object?> get props => [
    id,
    startDate,
    arrivedAt,
    waitingTime,
    quest,
    pointsSpent,
  ];
}
