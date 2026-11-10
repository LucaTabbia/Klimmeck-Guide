import 'package:equatable/equatable.dart';
import 'package:klimmeck_guide/models/asset_quantity.dart';
import 'package:klimmeck_guide/models/coins.dart';
import 'package:klimmeck_guide/models/enums/injury_type.dart';
import 'package:klimmeck_guide/models/enums/title_type.dart';
import 'package:klimmeck_guide/models/lore.dart';
import 'package:klimmeck_guide/models/quest/quest_enemy.dart';
import 'package:klimmeck_guide/models/quest_result/ambush_report.dart';
import 'package:klimmeck_guide/models/quest_result/quest_outcome.dart';
import 'package:klimmeck_guide/models/quest_result/quest_result_kind.dart';
import 'package:klimmeck_guide/models/quest_result/quest_result_quest.dart';
import 'package:klimmeck_guide/models/quest_result/quest_rewards.dart';
import 'package:klimmeck_guide/models/quest_result/spell_usage.dart';
import 'package:klimmeck_guide/models/spell.dart';

/// Esito di una quest o report di un'imboscata risolti dal backend
/// (`QuestResult`, BE Phase 9 / Phase 15): il foglio esiti lo mostra, il FE
/// non ricalcola nulla (regola 4).
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
    required this.enemies,
    required this.stagesCleared,
    required this.stagesTotal,
    required this.rescuedCharacters,
    this.kind = QuestResultKind.quest,
    this.ambush,
    this.acknowledgedAt,
    this.loreUnlocked = const [],
    this.injuriesHealed = const [],
    this.arrested = false,
    this.coinsLost,
    this.guardEncounter = false,
  });

  final String id;
  final QuestOutcome outcome;

  /// Istante UTC della risoluzione: ordina la coda dei fogli (D-08).
  final DateTime resolvedAt;
  final String characterId;
  final String userId;

  /// Istantanea della quest; `null` per un report d'imboscata (BE Phase 15 D-14).
  final QuestResultQuest? quest;
  final int hpBefore;
  final int hpAfter;

  /// Massimo dopo l'esito (BE §3): cresce con un passaggio di livello.
  final int maxLifePoints;
  final List<InjuryType> injuriesAdded;

  /// Ferite guarite dall'esito (BE Phase 18, D-02); vuota quando il filo non
  /// le manda.
  final List<InjuryType> injuriesHealed;

  /// Arresto alla fine di una crime (quick 261110-cgd): nessun premio, la
  /// prigione arriva sullo stato del personaggio.
  final bool arrested;

  /// Monete confiscate con l'arresto; `null` fuori dall'arresto o illeggibili.
  final Coins? coinsLost;

  /// Scontro alla fine di una guard (quick 261110-cgd): la paga raddoppiata
  /// di una vittoria è già nei premi del server.
  final bool guardEncounter;

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

  /// Le sole lore sbloccate da questo esito (BE Phase 16, D-04), nell'ordine
  /// del BE: tiro dello studio o prima vittoria su una specie.
  final List<Lore> loreUnlocked;

  /// Nemici affrontati, nell'ordine del BE (D-07); una voce malformata è scartata.
  final List<QuestEnemy> enemies;

  /// Solo per una dungeon (BE D-12): tappe superate e totali.
  final int? stagesCleared;
  final int? stagesTotal;
  final List<String> rescuedCharacters;

  /// Quest o imboscata (D-01); un BE più vecchio vale `quest`.
  final QuestResultKind kind;

  /// Solo per un'imboscata: istante e città (D-01).
  final AmbushReport? ambush;

  /// BE 9.2: istante della presa visione; assente prima del fragment del piano 09-12.
  final DateTime? acknowledgedAt;

  bool get isDeath => outcome == QuestOutcome.death;

  bool get isAmbush => kind == QuestResultKind.ambush;

  bool get hasLevelChanged => levelBefore != levelAfter;

  bool get hasTitleChanged => titleBefore != titleAfter;

  bool get hasRewards => !rewards.isEmpty;

  factory QuestResult.fromJson(Map<String, dynamic> json) {
    final kind = QuestResultKind.fromWire(json['kind']);
    final isAmbush = kind == QuestResultKind.ambush;
    return QuestResult(
      id: json['id'] as String,
      kind: kind,
      outcome:
          QuestOutcome.fromWire(json['outcome']) ??
          (throw const FormatException('unknown outcome')),
      resolvedAt: DateTime.parse(json['resolvedAt'] as String).toUtc(),
      characterId: json['character'] as String,
      userId: json['user'] as String,
      quest: isAmbush
          ? null
          : QuestResultQuest.fromJson(json['quest'] as Map<String, dynamic>),
      hpBefore: (json['hpBefore'] as num).toInt(),
      hpAfter: (json['hpAfter'] as num).toInt(),
      maxLifePoints: (json['maxLifePoints'] as num).toInt(),
      injuriesAdded: injuryTypesFrom(json['injuriesAdded'] as List),
      injuriesHealed: injuryTypesFrom(json['injuriesHealed']),
      arrested: json['arrested'] == true,
      coinsLost: _coinsFrom(json['coinsLost']),
      guardEncounter: json['guardEncounter'] == true,
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
      loreUnlocked: Lore.lenientRefsFrom(json['loreUnlocked']),
      enemies: QuestEnemy.lenientListFrom(json['enemies']),
      stagesCleared: _countFrom(json['stagesCleared']),
      stagesTotal: _countFrom(json['stagesTotal']),
      rescuedCharacters: List.unmodifiable(
        (json['rescuedCharacters'] as List).cast<String>(),
      ),
      ambush: isAmbush
          ? AmbushReport.fromJson(json['ambush'] as Map<String, dynamic>)
          : null,
      acknowledgedAt: _instantFrom(json['acknowledgedAt']),
    );
  }

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

  static Spell? _spellFrom(Object? json) =>
      json is Map<String, dynamic> ? Spell.fromJson(json) : null;

  static Coins? _coinsFrom(Object? json) =>
      json is Map<String, dynamic> ? Coins.fromJson(json) : null;

  static int? _countFrom(Object? json) => json is num ? json.toInt() : null;

  static DateTime? _instantFrom(Object? json) =>
      json is String ? DateTime.parse(json).toUtc() : null;

  Map<String, dynamic> toJson() => {
    'id': id,
    'outcome': outcome.name,
    'kind': kind.name,
    'resolvedAt': resolvedAt.toUtc().toIso8601String(),
    'character': characterId,
    'user': userId,
    'quest': quest?.toJson(),
    'hpBefore': hpBefore,
    'hpAfter': hpAfter,
    'maxLifePoints': maxLifePoints,
    'injuriesAdded': injuriesAdded.map((injury) => injury.name).toList(),
    'injuriesHealed': injuriesHealed.map((injury) => injury.name).toList(),
    'arrested': arrested,
    'coinsLost': coinsLost?.toJson(),
    'guardEncounter': guardEncounter,
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
    'loreUnlocked': loreUnlocked
        .map(
          (lore) => {'id': lore.id, 'name': lore.name, 'type': lore.type?.name},
        )
        .toList(),
    'enemies': enemies.map((entry) => entry.toJson()).toList(),
    'stagesCleared': stagesCleared,
    'stagesTotal': stagesTotal,
    'rescuedCharacters': rescuedCharacters,
    'ambush': ambush?.toJson(),
    if (acknowledgedAt != null)
      'acknowledgedAt': acknowledgedAt!.toUtc().toIso8601String(),
  };

  @override
  List<Object?> get props => [
    id,
    outcome,
    kind,
    resolvedAt,
    characterId,
    userId,
    quest,
    hpBefore,
    hpAfter,
    maxLifePoints,
    injuriesAdded,
    injuriesHealed,
    arrested,
    coinsLost,
    guardEncounter,
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
    loreUnlocked,
    enemies,
    stagesCleared,
    stagesTotal,
    rescuedCharacters,
    ambush,
    acknowledgedAt,
  ];
}
