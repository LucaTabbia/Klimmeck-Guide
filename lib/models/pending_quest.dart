import 'package:klimmeck_guide/models/quest.dart';
import 'package:klimmeck_guide/models/user.dart';

class PendingQuest {
  PendingQuest({
    required this.id,
    required this.startDate,
    required this.waitingTime,
    required this.quest,
    required this.requestingUser,
  });

  final String id;
  final DateTime? startDate;
  final int? waitingTime;
  final Quest? quest;
  final User? requestingUser;

  factory PendingQuest.fromJson(Map<String, dynamic> json) => PendingQuest(
    id: json["id"],
    startDate: json["startDate"] != null ? DateTime.parse(json["startDate"]) : null,
    waitingTime: json["waitingTime"] != null ? (json["waitingTime"] as num).toInt() : null,
    quest: json["quest"] != null ? Quest.fromJson(json["quest"]) : null,
    requestingUser: json["requestingUser"] != null ? User.fromJson(json["requestingUser"]) : null,
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "startDate": startDate?.toIso8601String(),
    "waitingTime": waitingTime,
    "quest": quest?.id,
    "requestingUser": requestingUser?.id,
  };
}
