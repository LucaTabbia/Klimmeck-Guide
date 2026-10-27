import 'package:klimmeck_guide/models/quest_result/quest_result.dart';

/// Istante di risoluzione di default dei risultati di test (UTC).
final DateTime questResultResolvedAt = DateTime.utc(2026, 10, 27, 12);

const String _defaultResolvedAt = '2026-10-27T12:00:00.000Z';

const Map<String, dynamic> _zeroCoins = {'gold': 0, 'silver': 0, 'copper': 0};

/// Consumabile o ricompensa `LootItem` (selezione `LootFragment.simpleFields`
/// più `description effect power`).
Map<String, dynamic> lootRewardJson({
  String id = 'loot-1',
  String name = 'Pozione curativa',
  int quantity = 1,
}) => {
  'quantity': quantity,
  'item': {
    'id': id,
    'name': name,
    'itemType': 'LootItem',
    'rarity': 'common',
    'description': 'Cura le ferite',
    'effect': 'heal',
    'power': 200,
  },
};

/// Ricompensa `EquipmentItem`: porta `equipType`, altrimenti diventerebbe loot (C5).
Map<String, dynamic> equipmentRewardJson({
  String id = 'eq-1',
  String name = 'Elmo di ferro',
  int quantity = 1,
}) => {
  'quantity': quantity,
  'item': {
    'id': id,
    'name': name,
    'itemType': 'EquipmentItem',
    'equipType': 'helm',
    'rarity': 'uncommon',
    'description': 'Un elmo robusto',
  },
};

/// Payload registrato di `QuestResult` (BE Phase 9, schema `10e5f43`): di
/// default una vittoria in una caccia. `acknowledgedAt` (BE 9.2) è scritto solo
/// se valorizzato.
Map<String, dynamic> questResultJson({
  String id = 'result-1',
  String outcome = 'success',
  String resolvedAt = _defaultResolvedAt,
  String character = 'c-1',
  String user = 'u-1',
  String questId = 'q-1',
  String questType = 'hunt',
  String questTitle = 'Lupi di Valantar',
  int hpBefore = 900,
  int hpAfter = 640,
  int maxLifePoints = 1200,
  List<Object?> injuriesAdded = const ['deepCut'],
  List<Map<String, dynamic>>? consumablesUsed,
  List<Map<String, dynamic>>? spellsUsed,
  Map<String, dynamic>? coins,
  List<Map<String, dynamic>>? rewardItems,
  int xpBefore = 200,
  int xpGained = 60,
  int xpAfter = 260,
  int levelBefore = 1,
  int levelAfter = 2,
  String titleBefore = 'rookie',
  String titleAfter = 'rookie',
  Map<String, dynamic>? spellLearned,
  bool hasEnemy = true,
  List<String> rescuedCharacters = const [],
  String? acknowledgedAt,
}) => {
  'id': id,
  'outcome': outcome,
  'resolvedAt': resolvedAt,
  'character': character,
  'user': user,
  'quest': {'id': questId, 'type': questType, 'title': questTitle},
  'hpBefore': hpBefore,
  'hpAfter': hpAfter,
  'maxLifePoints': maxLifePoints,
  'injuriesAdded': injuriesAdded,
  'consumablesUsed': consumablesUsed ?? [lootRewardJson()],
  'spellsUsed':
      spellsUsed ??
      [
        {
          'usages': 2,
          'spell': {'id': 'spell-1', 'name': 'Dardo di fuoco'},
        },
      ],
  'rewards': {
    'coins': coins ?? {'gold': 0, 'silver': 3, 'copper': 20},
    'items': rewardItems ?? [equipmentRewardJson()],
  },
  'xpBefore': xpBefore,
  'xpGained': xpGained,
  'xpAfter': xpAfter,
  'levelBefore': levelBefore,
  'levelAfter': levelAfter,
  'titleBefore': titleBefore,
  'titleAfter': titleAfter,
  'spellLearned': spellLearned,
  'enemy': hasEnemy
      ? {
          'id': 'enemy-1',
          'name': 'Lupo grigio',
          'imagePath': 'enemies/wolf.png',
        }
      : null,
  'rescuedCharacters': rescuedCharacters,
  if (acknowledgedAt != null) 'acknowledgedAt': acknowledgedAt,
};

Map<String, dynamic> successResultJson({
  String id = 'result-1',
  String resolvedAt = _defaultResolvedAt,
}) => questResultJson(id: id, resolvedAt: resolvedAt);

/// Sconfitta: il personaggio resta ferito in attesa di soccorso, niente ricompense.
Map<String, dynamic> failureResultJson({
  String id = 'result-fail',
  String resolvedAt = _defaultResolvedAt,
}) => questResultJson(
  id: id,
  resolvedAt: resolvedAt,
  outcome: 'failure',
  hpAfter: 1,
  coins: _zeroCoins,
  rewardItems: const [],
  xpGained: 0,
  xpAfter: 200,
  levelAfter: 1,
);

/// Salvato da un soccorso: la quest è l'aiuto, prima = dopo.
Map<String, dynamic> rescuedResultJson({
  String id = 'result-rescued',
  String resolvedAt = _defaultResolvedAt,
}) => _aidOutcomeJson(id: id, resolvedAt: resolvedAt, outcome: 'rescued');

/// Morte per soccorso mancato: la quest è l'aiuto, prima = dopo.
Map<String, dynamic> deathResultJson({
  String id = 'result-death',
  String resolvedAt = _defaultResolvedAt,
  String character = 'c-1',
}) => _aidOutcomeJson(
  id: id,
  resolvedAt: resolvedAt,
  outcome: 'death',
  character: character,
);

/// Missione chiusa dal GM: nessun nemico, cambio di titolo.
Map<String, dynamic> gmCompletedResultJson({
  String id = 'result-gm',
  String resolvedAt = _defaultResolvedAt,
}) => questResultJson(
  id: id,
  resolvedAt: resolvedAt,
  outcome: 'gmCompleted',
  questType: 'story',
  questTitle: 'La corona perduta',
  hasEnemy: false,
  hpAfter: 900,
  injuriesAdded: const [],
  consumablesUsed: const [],
  spellsUsed: const [],
  titleAfter: 'adventurer',
);

/// Vittoria di chi ha soccorso due avventurieri.
Map<String, dynamic> rescuerSuccessResultJson({
  String id = 'result-rescuer',
  String resolvedAt = _defaultResolvedAt,
}) => questResultJson(
  id: id,
  resolvedAt: resolvedAt,
  questType: 'aid',
  questTitle: 'Soccorso: Lupi di Valantar',
  rescuedCharacters: const ['c-2', 'c-3'],
);

Map<String, dynamic> _aidOutcomeJson({
  required String id,
  required String resolvedAt,
  required String outcome,
  String character = 'c-1',
}) => questResultJson(
  id: id,
  resolvedAt: resolvedAt,
  outcome: outcome,
  character: character,
  questType: 'aid',
  questTitle: 'Soccorso: Lupi di Valantar',
  hpBefore: 1,
  hpAfter: 1,
  injuriesAdded: const [],
  consumablesUsed: const [],
  spellsUsed: const [],
  coins: _zeroCoins,
  rewardItems: const [],
  xpGained: 0,
  xpAfter: 200,
  levelAfter: 1,
);

QuestResult questResult(Map<String, dynamic> json) =>
    QuestResult.fromJson(json);
