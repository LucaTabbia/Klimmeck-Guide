/// Voci della coda del GM come le seleziona il FE (10-RESEARCH F3); `pendingQuest` solo se passato, come dopo BE-HARD-08.
library;

export 'travel_fixtures.dart' show awaitingAidJson;

const String storyQuestId = 'quest-story-1';
const String worldMissionQuestId = 'quest-world-1';

Map<String, dynamic> pendingRequestJson({
  String id = 'pq-story-1',
  String questId = storyQuestId,
  String questTitle = 'La cripta di Valantar',
  String questType = 'story',
  List<Map<String, dynamic>> requiredAdventurers = const [
    {'title': null, 'count': 1},
  ],
  String characterId = 'char-aldo',
  String characterName = 'Aldo',
  String location = 'poi-valantar-marker',
  Map<String, dynamic>? activeTravel,
  Map<String, dynamic>? awaitingAid,
  Object? pendingQuest,
  String? startDate = '2026-10-29T10:00:00.000Z',
}) => {
  'id': id,
  'startDate': startDate,
  'quest': {
    'id': questId,
    'type': questType,
    'title': questTitle,
    'requiredAdventurers': requiredAdventurers,
  },
  'character': {
    'id': characterId,
    'name': characterName,
    'location': location,
    'activeTravel': activeTravel,
    'awaitingAid': awaitingAid,
    if (pendingQuest != null) 'pendingQuest': pendingQuest,
  },
};

Map<String, dynamic> queuedTravelJson({
  required DateTime endTime,
  String to = 'poi-borgo-marker',
}) => {'endTime': endTime.toUtc().toIso8601String(), 'to': to};

/// Una worldMission con un'entrata per nome, nello stesso ordine (BE: startDate asc).
List<Map<String, dynamic>> worldMissionEntriesJson({
  List<String> names = const ['Bea', 'Cosimo'],
  List<Map<String, dynamic>> requiredAdventurers = const [
    {'title': null, 'count': 3},
  ],
  Map<String, String> busyLanes = const {},
  Map<String, Map<String, dynamic>> travels = const {},
}) => [
  for (final (index, name) in names.indexed)
    pendingRequestJson(
      id: 'pq-world-${index + 1}',
      questId: worldMissionQuestId,
      questTitle: 'L\'assedio di Borgo Rovo',
      questType: 'worldMission',
      requiredAdventurers: requiredAdventurers,
      characterId: 'char-${name.toLowerCase()}',
      characterName: name,
      activeTravel: travels[name],
      pendingQuest: busyLanes[name],
      startDate: '2026-10-29T1${index + 1}:00:00.000Z',
    ),
];
