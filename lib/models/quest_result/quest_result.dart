import 'package:equatable/equatable.dart';
import 'package:klimmeck_guide/models/asset_quantity.dart';
import 'package:klimmeck_guide/models/enemy.dart';
import 'package:klimmeck_guide/models/enums/injury_type.dart';
import 'package:klimmeck_guide/models/enums/title_type.dart';
import 'package:klimmeck_guide/models/quest_result/quest_outcome.dart';
import 'package:klimmeck_guide/models/quest_result/quest_result_quest.dart';
import 'package:klimmeck_guide/models/quest_result/quest_rewards.dart';
import 'package:klimmeck_guide/models/quest_result/spell_usage.dart';
import 'package:klimmeck_guide/models/spell.dart';

/// Esito di una quest risolta dal backend (`QuestResult`, BE Phase 9): il
/// foglio esiti lo mostra, il FE non ricalcola nulla (regola 4).
class QuestResult extends Equatable {
  const QuestResult({
    required this.id,
    required this.outcome,
    required this.resolvedAt,
    required this.characterId,
    required this.userId,
    required this.quest,
    required this.hpBefore,
    required this.hpAfter,
    required this.maxLifePoints,
    required this.injuriesAdded,
    required this.consumablesUsed,
    required this.spellsUsed,
    required this.rewards,
    required this.xpBefore,
    required this.xpGained,
    required this.xpAfter,
    required this.levelBefore,
    required this.levelAfter,
    required this.titleBefore,
    required this.titleAfter,
    required this.spellLearned,
    required this.enemy,
    required this.rescuedCharacters,
    this.acknowledgedAt,
  });

  final String id;
  final QuestOutcome outcome;

  /// Istante UTC della risoluzione: ordina la coda dei fogli (D-08).
  final DateTime resolvedAt;
  final String characterId;
  final String userId;
  final QuestResultQuest quest;
  final int hpBefore;
  final int hpAfter;

  /// Massimo dopo l'esito (BE §3): cresce con un passaggio di livello.
  final int maxLifePoints;
  final List<InjuryType> injuriesAdded;
  final List<AssetQuantity> consumablesUsed;
  final List<SpellUsage> spellsUsed;
  final QuestRewards rewards;
  final int xpBefore;
  final int xpGained;
  final int xpAfter;
  final int levelBefore;
  final int levelAfter;

  /// `null` per un titolo sconosciuto al FE.
  final TitleType? titleBefore;
  final TitleType? titleAfter;
  final Spell? spellLearned;
  final Enemy? enemy;
  final List<String> rescuedCharacters;

  /// BE 9.2: istante della presa visione; assente prima del fragment del piano 09-12.
  final DateTime? acknowledgedAt;

  bool get isDeath => outcome == QuestOutcome.death;

  bool get hasLevelChanged => levelBefore != levelAfter;

  bool get hasTitleChanged => titleBefore != titleAfter;

  bool get hasRewards => !rewards.isEmpty;

  factory QuestResult.fromJson(Map<String, dynamic> json) => QuestResult(
    id: json['id'] as String,
    outcome:
        QuestOutcome.fromWire(json['outcome']) ??
        (throw const FormatException('unknown outcome')),
    resolvedAt: DateTime.parse(json['resolvedAt'] as String).toUtc(),
    characterId: json['character'] as String,
    userId: json['user'] as String,
    quest: QuestResultQuest.fromJson(json['quest'] as Map<String, dynamic>),
    hpBefore: (json['hpBefore'] as num).toInt(),
    hpAfter: (json['hpAfter'] as num).toInt(),
    maxLifePoints: (json['maxLifePoints'] as num).toInt(),
    injuriesAdded: _injuriesFrom(json['injuriesAdded'] as List),
    consumablesUsed: assetQuantitiesFrom(json['consumablesUsed']),
    spellsUsed: List.unmodifiable(
      (json['spellsUsed'] as List).whereType<Map<String, dynamic>>().map(
        SpellUsage.fromJson,
      ),
    ),
    rewards: QuestRewards.fromJson(json['rewards'] as Map<String, dynamic>),
    xpBefore: (json['xpBefore'] as num).toInt(),
    xpGained: (json['xpGained'] as num).toInt(),
    xpAfter: (json['xpAfter'] as num).toInt(),
    levelBefore: (json['levelBefore'] as num).toInt(),
    levelAfter: (json['levelAfter'] as num).toInt(),
    titleBefore: TitleType.values.asNameMap()[json['titleBefore']],
    titleAfter: TitleType.values.asNameMap()[json['titleAfter']],
    spellLearned: _spellFrom(json['spellLearned']),
    enemy: _enemyFrom(json['enemy']),
    rescuedCharacters: List.unmodifiable(
      (json['rescuedCharacters'] as List).cast<String>(),
    ),
    acknowledgedAt: _instantFrom(json['acknowledgedAt']),
  );

  /// Confine di parsing: un risultato malformato vale null, mai un'eccezione (T-9-01).
  static QuestResult? tryFromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    try {
      return QuestResult.fromJson(json);
    } on Object {
      return null;
    }
  }

  /// Voci `AssetQuantity` di un elenco; gli oggetti orfani (`item: null`) sono scartati.
  static List<AssetQuantity> assetQuantitiesFrom(Object? json) {
    if (json is! List) return const [];
    return List.unmodifiable(
      json
          .whereType<Map<String, dynamic>>()
          .map(AssetQuantity.fromJson)
          .where((entry) => entry.item != null),
    );
  }

  static List<InjuryType> _injuriesFrom(List<dynamic> names) {
    final injuries = InjuryType.values.asNameMap();
    return List.unmodifiable(
      names.map((name) => injuries[name]).whereType<InjuryType>(),
    );
  }

  static Spell? _spellFrom(Object? json) =>
      json is Map<String, dynamic> ? Spell.fromJson(json) : null;

  // Solo id, nome e immagine: altri campi del nemico farebbero fallire
  // `Enemy.fromJson` (BE §14).
  static Enemy? _enemyFrom(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    return Enemy.fromJson({
      'id': json['id'],
      'name': json['name'],
      'imagePath': json['imagePath'],
    });
  }

  static DateTime? _instantFrom(Object? json) =>
      json is String ? DateTime.parse(json).toUtc() : null;

  Map<String, dynamic> toJson() => {
    'id': id,
    'outcome': outcome.name,
    'resolvedAt': resolvedAt.toUtc().toIso8601String(),
    'character': characterId,
    'user': userId,
    'quest': quest.toJson(),
    'hpBefore': hpBefore,
    'hpAfter': hpAfter,
    'maxLifePoints': maxLifePoints,
    'injuriesAdded': injuriesAdded.map((injury) => injury.name).toList(),
    'consumablesUsed': consumablesUsed.map((entry) => entry.toJson()).toList(),
    'spellsUsed': spellsUsed.map((usage) => usage.toJson()).toList(),
    'rewards': rewards.toJson(),
    'xpBefore': xpBefore,
    'xpGained': xpGained,
    'xpAfter': xpAfter,
    'levelBefore': levelBefore,
    'levelAfter': levelAfter,
    'titleBefore': titleBefore?.name,
    'titleAfter': titleAfter?.name,
    'spellLearned': spellLearned == null
        ? null
        : {'id': spellLearned!.id, 'name': spellLearned!.name},
    'enemy': enemy == null
        ? null
        : {'id': enemy!.id, 'name': enemy!.name, 'imagePath': enemy!.imagePath},
    'rescuedCharacters': rescuedCharacters,
    if (acknowledgedAt != null)
      'acknowledgedAt': acknowledgedAt!.toUtc().toIso8601String(),
  };

  @override
  List<Object?> get props => [
    id,
    outcome,
    resolvedAt,
    characterId,
    userId,
    quest,
    hpBefore,
    hpAfter,
    maxLifePoints,
    injuriesAdded,
    consumablesUsed,
    spellsUsed,
    rewards,
    xpBefore,
    xpGained,
    xpAfter,
    levelBefore,
    levelAfter,
    titleBefore,
    titleAfter,
    spellLearned,
    enemy,
    rescuedCharacters,
    acknowledgedAt,
  ];
}
