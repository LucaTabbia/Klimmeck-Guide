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
  final DateTime startDate;
  final int waitingTime;
  final Quest quest;
  final User requestingUser;

  factory PendingQuest.fromJson(Map<String, dynamic> json) => PendingQuest(
    id: json["id"],
    startDate: DateTime(json["startDate"]),
    waitingTime: json["waitingTime"].toDouble(),
    quest: Quest.fromJson(json["quest"]),
    requestingUser: User.fromJson(json["requestingUser"]),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "startDate": startDate.toIso8601String(),
    "waitingTime": waitingTime,
    "quest": quest.id,
    "requestingUser": requestingUser.id,
  };
}
