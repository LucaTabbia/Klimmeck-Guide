import 'package:klimmeck_guide/models/character.dart';
import 'package:klimmeck_guide/models/pending_quest.dart';
import 'package:klimmeck_guide/models/quest.dart';

class User {
  User({
    required this.id,
    required this.twitchId,
    required this.twitchPoints,
    required this.completedQuests,
    required this.pendingQuest,
    required this.currentCharacter,
  });

  final String id;
  final String twitchId;
  int twitchPoints;
  List<Quest> completedQuests = const [];
  PendingQuest? pendingQuest;
  Character currentCharacter;

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json["id"],
    twitchId: json["twitchId"],
    twitchPoints: json["twitchId"].toInt(),
    completedQuests: List<Quest>.from(json['completedQuests'].map((x) => Quest.fromJson(x))),
    pendingQuest: PendingQuest.fromJson(json['pendingQuest']),
    currentCharacter: Character.fromJson(json["currentCharacter"]),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "twitchId": twitchId,
    "twitchPoints": twitchPoints,
    "completedQuests": completedQuests.map((s) => s.id).toList(),
    "pendingQuest": pendingQuest?.id,
    "currentCharacter": currentCharacter.id,
  };
}
