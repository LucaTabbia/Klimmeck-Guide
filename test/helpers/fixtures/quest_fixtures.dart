import 'package:klimmeck_guide/models/character/character_quests.dart';
import 'package:klimmeck_guide/models/enums/title_type.dart';
import 'package:klimmeck_guide/models/quest/quest_viewer.dart';
import 'package:klimmeck_guide/models/quest/quest.dart';

/// Voce `QuestEnemy` sul filo (BE Phase 13 D-01): selezione `enemies { quantity known enemy { id name imagePath xp } }`; `known` vale `true` di default (BE Phase 16, D-03).
Map<String, dynamic> questEnemyJson({
  String id = 'enemy-1',
  String? name = 'Lupo grigio',
  String? imagePath,
  int? xp = 10,
  int quantity = 1,
  bool known = true,
}) => {
  'quantity': quantity,
  'known': known,
  'enemy': {'id': id, 'name': name, 'imagePath': imagePath, 'xp': xp},
};

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
  List<Map<String, dynamic>>? enemies,
  String? description,
  Map<String, dynamic>? prizes,
  List<Map<String, dynamic>>? lore,
  List<Map<String, dynamic>>? recommendedLoot,
  bool? noEffect,
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
    if (enemies != null) 'enemies': enemies,
    if (description != null) 'description': description,
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
  if (prizes != null) 'prizes': prizes,
  'registeredAdventurers': registered,
  if (noEffect != null) 'noEffect': noEffect,
};

/// `prizes.cure` sul filo (BE Phase 18): quota di vita e ferite guarite.
Map<String, dynamic> questCureJson({
  Object? share = 0.5,
  Object? canHeal = const ['contusion', 'deepCut'],
}) => {'lifePointsShare': share, 'canHeal': canHeal};

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
  int? currentLifePoints,
  int? maxLifePoints,
  List<String>? injuries,
}) => {
  'id': id,
  'status': {
    'title': title,
    'location': {
      'id': locationId,
      'location': [1.0, 2.0],
    },
    if (currentLifePoints != null) 'currentLifePoints': currentLifePoints,
    if (maxLifePoints != null) 'maxLifePoints': maxLifePoints,
    if (injuries != null) 'injuries': injuries,
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
  List<Map<String, dynamic>>? enemies,
  String? description,
  Map<String, dynamic>? prizes,
  List<Map<String, dynamic>>? lore,
  List<Map<String, dynamic>>? recommendedLoot,
  bool? noEffect,
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
    enemies: enemies,
    description: description,
    prizes: prizes,
    lore: lore,
    recommendedLoot: recommendedLoot,
    noEffect: noEffect,
  ),
);

QuestViewer buildViewer({
  String characterId = 'c-1',
  TitleType? title = TitleType.rookie,
  CharacterQuests? quests,
  Set<String>? cityPointIds = const {'poi-1'},
  int? twitchPoints = 5000,
  Duration? imprisonedFor,
}) => QuestViewer(
  characterId: characterId,
  title: title,
  quests: quests,
  cityPointIds: cityPointIds,
  twitchPoints: twitchPoints,
  imprisonedFor: imprisonedFor,
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
