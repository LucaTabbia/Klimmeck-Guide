import 'package:equatable/equatable.dart';
import 'package:klimmeck_guide/models/enums/injury_type.dart';
import 'package:klimmeck_guide/models/mission/mission_enemy.dart';
import 'package:klimmeck_guide/models/mission/mission_entries.dart';

/// Oggetto e quantità (`MissionItemUsage { item quantity }`): usato o disponibile.
class MissionItemUsage extends Equatable {
  const MissionItemUsage({required this.itemId, required this.quantity});

  final String itemId;
  final int quantity;

  static MissionItemUsage? tryFromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final itemId = json['item'];
    final quantity = missionIntOf(json['quantity']);
    if (itemId is! String || quantity == null) return null;
    return MissionItemUsage(itemId: itemId, quantity: quantity);
  }

  @override
  List<Object?> get props => [itemId, quantity];
}

/// Magia e usi (`MissionSpellUsage { spell usages }`): usati o disponibili.
class MissionSpellUsage extends Equatable {
  const MissionSpellUsage({required this.spellId, required this.usages});

  final String spellId;
  final int usages;

  static MissionSpellUsage? tryFromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final spellId = json['spell'];
    final usages = missionIntOf(json['usages']);
    if (spellId is! String || usages == null) return null;
    return MissionSpellUsage(spellId: spellId, usages: usages);
  }

  @override
  List<Object?> get props => [spellId, usages];
}

/// Effetto di uno scontro su un personaggio, simulato dal motore o corretto dall'oste.
class MissionFightEffects extends Equatable {
  const MissionFightEffects({
    required this.hpAfter,
    this.injuriesAdded = const [],
    this.consumablesUsed = const [],
    this.spellsUsed = const [],
  });

  final int hpAfter;

  /// Ferite che lo scontro aggiunge (D-14).
  final List<InjuryType> injuriesAdded;
  final List<MissionItemUsage> consumablesUsed;
  final List<MissionSpellUsage> spellsUsed;

  /// Confine di parsing: senza `hpAfter` vale `null`.
  static MissionFightEffects? tryFromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final hpAfter = missionIntOf(json['hpAfter']);
    if (hpAfter == null) return null;
    return MissionFightEffects(
      hpAfter: hpAfter,
      injuriesAdded: injuryTypesFrom(json['injuriesAdded']),
      consumablesUsed: missionEntriesOf(
        json['consumablesUsed'],
        MissionItemUsage.tryFromJson,
      ),
      spellsUsed: missionEntriesOf(
        json['spellsUsed'],
        MissionSpellUsage.tryFromJson,
      ),
    );
  }

  @override
  List<Object?> get props => [
    hpAfter,
    injuriesAdded,
    consumablesUsed,
    spellsUsed,
  ];
}

/// Esito di uno scontro per un personaggio: i limiti all'inizio dello scontro
/// (`hpBefore`, `injuriesBefore`, `consumablesAvailable`, `spellsAvailable`)
/// sono serviti dal BE, mai calcolati (D-14, D-17).
class MissionFightOutcome extends Equatable {
  const MissionFightOutcome({
    required this.characterId,
    required this.hpBefore,
    this.injuriesBefore = const [],
    this.consumablesAvailable = const [],
    this.spellsAvailable = const [],
    this.simulated,
    this.corrected,
  });

  final String characterId;
  final int hpBefore;

  /// Ferite che il personaggio aveva già: mostrate, non rimovibili (D-14).
  final List<InjuryType> injuriesBefore;
  final List<MissionItemUsage> consumablesAvailable;
  final List<MissionSpellUsage> spellsAvailable;

  /// `null` = scontro non simulato o invalidato (D-24).
  final MissionFightEffects? simulated;

  /// `null` = nessuna correzione dell'oste.
  final MissionFightEffects? corrected;

  /// Effetto che vale per lo scontro: la correzione vince sulla simulazione (D-06).
  MissionFightEffects? get effective => corrected ?? simulated;

  /// Confine di parsing: senza `character` o `hpBefore` vale `null`.
  static MissionFightOutcome? tryFromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final characterId = json['character'];
    final hpBefore = missionIntOf(json['hpBefore']);
    if (characterId is! String || hpBefore == null) return null;
    return MissionFightOutcome(
      characterId: characterId,
      hpBefore: hpBefore,
      injuriesBefore: injuryTypesFrom(json['injuriesBefore']),
      consumablesAvailable: missionEntriesOf(
        json['consumablesAvailable'],
        MissionItemUsage.tryFromJson,
      ),
      spellsAvailable: missionEntriesOf(
        json['spellsAvailable'],
        MissionSpellUsage.tryFromJson,
      ),
      simulated: MissionFightEffects.tryFromJson(json['simulated']),
      corrected: MissionFightEffects.tryFromJson(json['corrected']),
    );
  }

  @override
  List<Object?> get props => [
    characterId,
    hpBefore,
    injuriesBefore,
    consumablesAvailable,
    spellsAvailable,
    simulated,
    corrected,
  ];
}

/// Verdetto unico dello scontro (D-21).
enum MissionFightVerdict {
  success('Vittoria'),
  failure('Sconfitta');

  const MissionFightVerdict(this.label);

  final String label;
}

/// Nemico di uno scontro con la sua quantità.
class MissionFightEnemy extends Equatable {
  const MissionFightEnemy({required this.enemy, required this.quantity});

  final MissionEnemy enemy;
  final int quantity;

  static MissionFightEnemy? tryFromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final enemy = MissionEnemy.tryFromJson(json['enemy']);
    final quantity = missionIntOf(json['quantity']);
    if (enemy == null || quantity == null) return null;
    return MissionFightEnemy(enemy: enemy, quantity: quantity);
  }

  @override
  List<Object?> get props => [enemy, quantity];
}

/// Scontro della bozza: nemici, esiti per personaggio e verdetto servito.
class MissionFight extends Equatable {
  const MissionFight({
    this.enemies = const [],
    this.outcomes = const [],
    this.verdict,
  });

  final List<MissionFightEnemy> enemies;
  final List<MissionFightOutcome> outcomes;

  /// `null` = da simulare (D-24).
  final MissionFightVerdict? verdict;

  /// Simulato = verdetto servito presente; l'app non decide mai se è scaduto (D-24).
  bool get isSimulated => verdict != null;

  MissionFightOutcome? outcomeOf(String characterId) {
    for (final outcome in outcomes) {
      if (outcome.characterId == characterId) return outcome;
    }
    return null;
  }

  static MissionFight? tryFromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    return MissionFight(
      enemies: missionEntriesOf(json['enemies'], MissionFightEnemy.tryFromJson),
      outcomes: missionEntriesOf(
        json['outcomes'],
        MissionFightOutcome.tryFromJson,
      ),
      verdict: MissionFightVerdict.values.asNameMap()[json['verdict']],
    );
  }

  @override
  List<Object?> get props => [enemies, outcomes, verdict];
}
