import 'package:klimmeck_guide/models/character/character_quests.dart';
import 'package:klimmeck_guide/models/enums/title_type.dart';
import 'package:klimmeck_guide/models/quest/quest_viewer.dart';
import 'package:klimmeck_guide/models/quest/quest.dart';

/// Quest JSON nella forma proposta dal BE Phase 8 (D-28): slot per rango e
/// registrazioni con titolo.
Map<String, dynamic> questJson({
  String id = 'q-1',
  String type = 'enemy',
  String title = 'Il lupo del bosco',
  String? minTitle = 'rookie',
  int? requiredPoints,
  List<Map<String, dynamic>>? slots,
  List<Object> registered = const [],
  String markerId = 'poi-1',
  int? timeToComplete = 60000,
  Map<String, dynamic>? enemy,
  List<Map<String, dynamic>>? lore,
  List<Map<String, dynamic>>? recommendedLoot,
}) => {
  'id': id,
  'infos': {
    'title': title,
    'type': type,
    'timeToComplete': timeToComplete,
    'markerLocation': {
      'id': markerId,
      'location': [1.0, 2.0],
    },
    if (enemy != null) 'enemy': enemy,
    if (lore != null) 'relatedLore': lore,
  },
  'requirements': {
    'minTitle': minTitle,
    'requiredPoints': requiredPoints,
    'requiredAdventurers':
        slots ??
        [
          {'title': null, 'count': 1},
        ],
    if (recommendedLoot != null) 'recommendedLoot': recommendedLoot,
  },
  'registeredAdventurers': registered,
};

/// Forma Phase 7 oggi su `develop`: capienza Int e id dei registrati.
Map<String, dynamic> legacyQuestJson({
  String id = 'q-legacy',
  String type = 'worldMission',
  int requiredAdventurers = 1,
  List<String> registered = const ['c-1'],
}) => {
  ...questJson(id: id, type: type),
  'requirements': {
    'minTitle': 'rookie',
    'requiredPoints': 3000,
    'requiredAdventurers': requiredAdventurers,
  },
  'registeredAdventurers': registered,
};

Map<String, dynamic> laneJson({
  String id = 'pq-1',
  String questId = 'q-1',
  String? startDate = '2026-10-21T10:00:00.000Z',
  String? arrivedAt,
  int pointsSpent = 0,
}) => {
  'id': id,
  'startDate': startDate,
  'arrivedAt': arrivedAt,
  'waitingTime': 60000.0,
  'pointsSpent': pointsSpent,
  'quest': {'id': questId},
};

Map<String, dynamic> characterWithLanesJson({
  String id = 'c-1',
  String title = 'rookie',
  String locationId = 'city-marker-1',
  List<String> completedQuestIds = const [],
  Map<String, dynamic>? pendingQuest,
  Map<String, dynamic>? activeStoryQuest,
  Map<String, dynamic>? activeWorldMissionQuest,
}) => {
  'id': id,
  'status': {
    'title': title,
    'location': {
      'id': locationId,
      'location': [1.0, 2.0],
    },
  },
  'quests': {
    'completedQuests': [
      for (final q in completedQuestIds) {'id': q},
    ],
    'pendingQuest': pendingQuest,
    'activeStoryQuest': activeStoryQuest,
    'activeWorldMissionQuest': activeWorldMissionQuest,
  },
};

Quest buildQuest({
  String id = 'q-1',
  String type = 'enemy',
  String title = 'Il lupo del bosco',
  String? minTitle = 'rookie',
  int? requiredPoints,
  List<Map<String, dynamic>>? slots,
  List<Object> registered = const [],
  String markerId = 'poi-1',
  int? timeToComplete = 60000,
  Map<String, dynamic>? enemy,
  List<Map<String, dynamic>>? lore,
  List<Map<String, dynamic>>? recommendedLoot,
}) => Quest.fromJson(
  questJson(
    id: id,
    type: type,
    title: title,
    minTitle: minTitle,
    requiredPoints: requiredPoints,
    slots: slots,
    registered: registered,
    markerId: markerId,
    timeToComplete: timeToComplete,
    enemy: enemy,
    lore: lore,
    recommendedLoot: recommendedLoot,
  ),
);

QuestViewer buildViewer({
  String characterId = 'c-1',
  TitleType? title = TitleType.rookie,
  CharacterQuests? quests,
  Set<String>? cityPointIds = const {'poi-1'},
  int? twitchPoints = 5000,
}) => QuestViewer(
  characterId: characterId,
  title: title,
  quests: quests,
  cityPointIds: cityPointIds,
  twitchPoints: twitchPoints,
);

CharacterQuests buildLanes({
  Map<String, dynamic>? pendingQuest,
  Map<String, dynamic>? activeStoryQuest,
  Map<String, dynamic>? activeWorldMissionQuest,
  List<String> completedQuestIds = const [],
}) => CharacterQuests.fromJson({
  'completedQuests': [
    for (final q in completedQuestIds) {'id': q},
  ],
  'pendingQuest': pendingQuest,
  'activeStoryQuest': activeStoryQuest,
  'activeWorldMissionQuest': activeWorldMissionQuest,
});
