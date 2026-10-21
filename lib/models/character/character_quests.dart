import 'package:equatable/equatable.dart';
import 'package:klimmeck_guide/models/pending_quest.dart';
import 'package:klimmeck_guide/models/quest/quest.dart';

/// Tre corsie indipendenti (BE Phase 7): standard, story, worldMission. Ogni
/// corsia porta solo `quest { id }`: la quest si risolve dalla board.
class CharacterQuests extends Equatable {
  const CharacterQuests({
    required this.completedQuests,
    required this.pendingQuest,
    this.activeStoryQuest,
    this.activeWorldMissionQuest,
  });

  final List<Quest>? completedQuests;
  final PendingQuest? pendingQuest;
  final PendingQuest? activeStoryQuest;
  final PendingQuest? activeWorldMissionQuest;

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
        activeStoryQuest: json["activeStoryQuest"] != null
            ? PendingQuest.fromJson(json["activeStoryQuest"])
            : null,
        activeWorldMissionQuest: json["activeWorldMissionQuest"] != null
            ? PendingQuest.fromJson(json["activeWorldMissionQuest"])
            : null,
      );

  Map<String, dynamic> toJson() => {
    "completedQuests": completedQuests?.map((s) => s.id).toList() ?? [],
    "pendingQuest": pendingQuest?.id,
    "activeStoryQuest": activeStoryQuest?.id,
    "activeWorldMissionQuest": activeWorldMissionQuest?.id,
  };

  CharacterQuests copyWith({
    List<Quest>? completedQuests,
    PendingQuest? pendingQuest,
    PendingQuest? activeStoryQuest,
    PendingQuest? activeWorldMissionQuest,
  }) {
    return CharacterQuests(
      completedQuests: completedQuests ?? this.completedQuests,
      pendingQuest: pendingQuest ?? this.pendingQuest,
      activeStoryQuest: activeStoryQuest ?? this.activeStoryQuest,
      activeWorldMissionQuest:
          activeWorldMissionQuest ?? this.activeWorldMissionQuest,
    );
  }

  @override
  List<Object?> get props => [
    completedQuests,
    pendingQuest,
    activeStoryQuest,
    activeWorldMissionQuest,
  ];
}
