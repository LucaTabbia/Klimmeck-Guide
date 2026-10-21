import '../character/character_quests.dart';
import '../enums/quest_type.dart';
import '../pending_quest.dart';

enum QuestLane { standard, story, worldMission }

QuestLane laneOf(QuestType type) => switch (type) {
  QuestType.story => QuestLane.story,
  QuestType.worldMission => QuestLane.worldMission,
  _ => QuestLane.standard,
};

/// Tipi con registrazione e capienza sulla Quest (BE Phase 7 D-03 + Phase 8 D-27).
const Set<QuestType> registeredQuestTypes = {
  QuestType.worldMission,
  QuestType.boss,
  QuestType.enemy,
  QuestType.aid,
};

/// Tipi non ripetibili (BE Phase 7 §3).
const Set<QuestType> nonRepeatableQuestTypes = {
  QuestType.story,
  QuestType.worldMission,
  QuestType.enemy,
  QuestType.boss,
  QuestType.aid,
};

PendingQuest? laneQuestOf(CharacterQuests? quests, QuestLane lane) =>
    switch (lane) {
      QuestLane.standard => quests?.pendingQuest,
      QuestLane.story => quests?.activeStoryQuest,
      QuestLane.worldMission => quests?.activeWorldMissionQuest,
    };
