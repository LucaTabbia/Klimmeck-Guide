import 'package:klimmeck_guide/models/quest/quest.dart';

class PendingQuest {
  PendingQuest({
    required this.id,
    required this.startDate,
    required this.waitingTime,
    required this.quest,
  });

  final String id;
  final DateTime? startDate;
  final int? waitingTime;
  final Quest? quest;

  factory PendingQuest.fromJson(Map<String, dynamic> json) => PendingQuest(
    id: json["id"],
    startDate: json["startDate"] != null ? DateTime.parse(json["startDate"]) : null,
    waitingTime: json["waitingTime"] != null ? (json["waitingTime"] as num).toInt() : null,
    quest: json["quest"] != null ? Quest.fromJson(json["quest"]) : null,
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "startDate": startDate?.toIso8601String(),
    "waitingTime": waitingTime,
    "quest": quest?.id,
  };
}
