/// Bozza del flusso guidato come la serve il BE Phase 22 (22-RESEARCH §Q9 + D-17).
library;

import 'pending_request_fixtures.dart';

const String missionDraftStartedAt = '2026-11-14T10:00:00.000Z';
const String missionDraftUpdatedAt = '2026-11-14T10:05:00.000Z';

Map<String, dynamic> missionEnemyJson({
  String id = 'enemy-wolf',
  String name = 'Lupo',
  String? imagePath = 'enemy_wolf_svg',
  int? xp = 30,
  int? lifePoints = 120,
  bool legendary = false,
}) => {
  'id': id,
  'name': name,
  'imagePath': imagePath,
  'xp': xp,
  'lifePoints': lifePoints,
  'legendary': legendary,
};

Map<String, dynamic> missionItemUsageJson({
  String item = potionItemId,
  int quantity = 1,
}) => {'item': item, 'quantity': quantity};

Map<String, dynamic> missionSpellUsageJson({
  String spell = fireballSpellId,
  int usages = 1,
}) => {'spell': spell, 'usages': usages};

Map<String, dynamic> missionEffectsJson({
  int hpAfter = 700,
  List<String> injuriesAdded = const ['crushedRightHand'],
  List<Map<String, dynamic>> consumablesUsed = const [],
  List<Map<String, dynamic>> spellsUsed = const [],
}) => {
  'hpAfter': hpAfter,
  'injuriesAdded': injuriesAdded,
  'consumablesUsed': consumablesUsed,
  'spellsUsed': spellsUsed,
};

Map<String, dynamic> missionOutcomeJson({
  String character = 'char-aldo',
  int? hpBefore = 800,
  List<String> injuriesBefore = const ['blackEye'],
  List<Map<String, dynamic>> consumablesAvailable = const [
    {'item': potionItemId, 'quantity': 2},
  ],
  List<Map<String, dynamic>> spellsAvailable = const [
    {'spell': fireballSpellId, 'usages': 2},
  ],
  Map<String, dynamic>? simulated,
  Map<String, dynamic>? corrected,
}) => {
  'character': character,
  'hpBefore': hpBefore,
  'injuriesBefore': injuriesBefore,
  'consumablesAvailable': consumablesAvailable,
  'spellsAvailable': spellsAvailable,
  'simulated': simulated,
  'corrected': corrected,
};

Map<String, dynamic> missionFightEnemyJson({
  Map<String, dynamic>? enemy,
  int quantity = 3,
}) => {'enemy': enemy ?? missionEnemyJson(), 'quantity': quantity};

Map<String, dynamic> missionFightJson({
  List<Map<String, dynamic>>? enemies,
  List<Map<String, dynamic>> outcomes = const [],
  String? verdict,
}) => {
  'enemies': enemies ?? [missionFightEnemyJson()],
  'outcomes': outcomes,
  'verdict': verdict,
};

Map<String, dynamic> missionParticipantJson({
  String character = 'char-aldo',
  String name = 'Aldo',
  String title = 'paladin',
  int? maxLifePoints = 1000,
  String pendingQuest = 'pq-world-1',
}) => {
  'character': character,
  'name': name,
  'title': title,
  'maxLifePoints': maxLifePoints,
  'pendingQuest': pendingQuest,
};

Map<String, dynamic> missionPrizeJson({
  String character = 'char-aldo',
  Map<String, dynamic> coins = const {'gold': 2, 'silver': 0, 'copper': 0},
  int? xp = 150,
  List<Map<String, dynamic>> items = const [],
  String? pet,
  String? spell,
  Map<String, dynamic>? cure,
}) => {
  'character': character,
  'coins': coins,
  'xp': xp,
  'items': items,
  'pet': pet,
  'spell': spell,
  'cure': cure,
};

Map<String, dynamic> missionDraftJson({
  String? id = 'draft-1',
  String? quest = worldMissionQuestId,
  String questType = 'worldMission',
  String step = 'teleport',
  String? place,
  List<Map<String, dynamic>>? participants,
  List<Map<String, dynamic>> fights = const [],
  List<Map<String, dynamic>> prizes = const [],
}) => {
  'id': id,
  'quest': quest,
  'questType': questType,
  'step': step,
  'place': place,
  'participants': participants ?? [missionParticipantJson()],
  'fights': fights,
  'prizes': prizes,
  'startedAt': missionDraftStartedAt,
  'updatedAt': missionDraftUpdatedAt,
};

Map<String, dynamic> missionPrizeOptionsJson({
  String character = 'char-aldo',
  String title = 'paladin',
  String maxRarity = 'rare',
  List<Map<String, dynamic>> equipment = const [],
  List<Map<String, dynamic>> loot = const [],
  List<Map<String, dynamic>> pets = const [],
  List<Map<String, dynamic>> spells = const [],
  Map<String, dynamic>? block,
}) => {
  'character': character,
  'title': title,
  'maxRarity': maxRarity,
  'equipment': equipment,
  'loot': loot,
  'pets': pets,
  'spells': spells,
  'block': block ?? <String, dynamic>{'randomLoot': <Object>[]},
};
