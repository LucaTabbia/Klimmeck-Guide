import 'package:equatable/equatable.dart';
import 'package:klimmeck_guide/models/pending_quest.dart';
import 'package:klimmeck_guide/models/quest/quest.dart';

class CharacterQuests extends Equatable {
  const CharacterQuests({
    required this.completedQuests,
    required this.pendingQuest,
  });

  final List<Quest>? completedQuests;
  final PendingQuest? pendingQuest;

  factory CharacterQuests.fromJson(Map<String, dynamic> json) =>
      CharacterQuests(
        completedQuests: json["completedQuests"] != null
            ? List<Quest>.from(
                json["completedQuests"].map((x) => Quest.fromJson(x)),
              )
            : [],
        pendingQuest: json["pendingQuest"] != null
            ? PendingQuest.fromJson(json["pendingQuest"])
            : null,
      );

  Map<String, dynamic> toJson() => {
    "completedQuests": completedQuests?.map((s) => s.id).toList() ?? [],
    "pendingQuest": pendingQuest?.id,
  };

  CharacterQuests copyWith({
    List<Quest>? completedQuests,
    PendingQuest? pendingQuest,
  }) {
    return CharacterQuests(
      completedQuests: completedQuests ?? this.completedQuests,
      pendingQuest: pendingQuest ?? this.pendingQuest,
    );
  }

  @override
  List<Object?> get props => [completedQuests, pendingQuest];
}
