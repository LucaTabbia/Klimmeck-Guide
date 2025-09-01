import 'package:klimmeck_guide/models/pending_quest.dart';
import 'package:klimmeck_guide/models/quest/quest.dart';

class CharacterQuests {
  CharacterQuests({required this.completedQuests, required this.pendingQuest});

  List<Quest>? completedQuests;
  PendingQuest? pendingQuest;

  factory CharacterQuests.fromJson(Map<String, dynamic> json) => CharacterQuests(
    completedQuests: json["completedQuests"] != null
        ? List<Quest>.from(json["completedQuests"].map((x) => Quest.fromJson(x)))
        : [],
    pendingQuest: json["pendingQuest"] != null ? PendingQuest.fromJson(json["pendingQuest"]) : null,
  );

  Map<String, dynamic> toJson() => {
    "completedQuests": completedQuests?.map((s) => s.id).toList() ?? [],
    "pendingQuest": pendingQuest?.id,
  };
}
