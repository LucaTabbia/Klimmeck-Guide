import 'package:klimmeck_guide/models/pending_quest.dart';
import 'package:klimmeck_guide/models/quest.dart';

import 'character.dart';
import 'enums/role_type.dart';

class User {
  User({
    required this.id,
    required this.twitchId,
    required this.twitchPoints,
    required this.completedQuests,
    required this.pendingQuest,
    required this.currentCharacter,
    required this.role,
  });

  final String id;
  final String? twitchId;
  final RoleType? role;
  int? twitchPoints;
  List<Quest>? completedQuests;
  PendingQuest? pendingQuest;
  Character? currentCharacter;

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json["id"],
    twitchId: json["twitchId"],
    twitchPoints: (json["twitchPoints"] as num?)?.toInt(),
    completedQuests: json["completedQuests"] != null
        ? List<Quest>.from(json["completedQuests"].map((x) => Quest.fromJson(x)))
        : [],
    pendingQuest: json["pendingQuest"] != null ? PendingQuest.fromJson(json["pendingQuest"]) : null,
    currentCharacter: json["currentCharacter"] != null
        ? Character.fromJson(json["currentCharacter"])
        : null,
    role: json["role"] != null ? RoleType.values.byName(json["role"]) : null,
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "twitchId": twitchId,
    "twitchPoints": twitchPoints,
    "completedQuests": completedQuests?.map((s) => s.id).toList() ?? [],
    "pendingQuest": pendingQuest?.id,
    "currentCharacter": currentCharacter?.id,
    "role": role?.name,
  };
}
