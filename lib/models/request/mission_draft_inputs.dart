import 'dart:math' as math;

import 'package:equatable/equatable.dart';
import 'package:klimmeck_guide/models/coins.dart';
import 'package:klimmeck_guide/models/enums/injury_type.dart';
import 'package:klimmeck_guide/models/mission/mission_draft.dart';
import 'package:klimmeck_guide/models/mission/mission_fight.dart';
import 'package:klimmeck_guide/models/mission/mission_limits.dart';
import 'package:klimmeck_guide/models/mission/mission_prize.dart';

/// Nemico e quantità di uno scontro (`MissionEnemyInput`).
class MissionEnemyInput extends Equatable {
  const MissionEnemyInput({required this.enemyId, required this.quantity});

  final String enemyId;
  final int quantity;

  static MissionEnemyInput of(MissionFightEnemy served) =>
      MissionEnemyInput(enemyId: served.enemy.id, quantity: served.quantity);

  Map<String, dynamic> toJson() => {'enemy': enemyId, 'quantity': quantity};

  @override
  List<Object?> get props => [enemyId, quantity];
}

/// Correzione dell'oste per un personaggio (`ParticipantOverrideInput`): manda
/// sempre l'effetto COMPLETO dello scontro, non solo ciò che è cambiato (D-14).
class MissionCorrection extends Equatable {
  const MissionCorrection({
    required this.characterId,
    required this.hpAfter,
    this.injuries = const [],
    this.consumablesUsed = const {},
    this.spellsUsed = const {},
  });

  factory MissionCorrection.fromEffects(
    String characterId,
    MissionFightEffects effects,
  ) => MissionCorrection(
    characterId: characterId,
    hpAfter: effects.hpAfter,
    injuries: List.unmodifiable(effects.injuriesAdded),
    consumablesUsed: Map.unmodifiable({
      for (final usage in effects.consumablesUsed) usage.itemId: usage.quantity,
    }),
    spellsUsed: Map.unmodifiable({
      for (final usage in effects.spellsUsed) usage.spellId: usage.usages,
    }),
  );

  final String characterId;
  final int hpAfter;

  /// Tutte le ferite che lo scontro aggiunge dopo la correzione (D-14).
  final List<InjuryType> injuries;

  /// Id dell'oggetto → quantità usata.
  final Map<String, int> consumablesUsed;

  /// Id della magia → usi consumati.
  final Map<String, int> spellsUsed;

  MissionCorrection withHp(int hp) => _copy(hpAfter: hp);

  MissionCorrection withInjuryToggled(InjuryType injury) => _copy(
    injuries: injuries.contains(injury)
        ? injuries.where((existing) => existing != injury).toList()
        : [...injuries, injury],
  );

  MissionCorrection withConsumableUsed(String itemId, int quantity) =>
      _copy(consumablesUsed: {...consumablesUsed, itemId: quantity});

  MissionCorrection withSpellUsed(String spellId, int usages) =>
      _copy(spellsUsed: {...spellsUsed, spellId: usages});

  MissionCorrection _copy({
    int? hpAfter,
    List<InjuryType>? injuries,
    Map<String, int>? consumablesUsed,
    Map<String, int>? spellsUsed,
  }) => MissionCorrection(
    characterId: characterId,
    hpAfter: hpAfter ?? this.hpAfter,
    injuries: List.unmodifiable(injuries ?? this.injuries),
    consumablesUsed: Map.unmodifiable(consumablesUsed ?? this.consumablesUsed),
    spellsUsed: Map.unmodifiable(spellsUsed ?? this.spellsUsed),
  );

  Map<String, dynamic> toJson() => {
    'characterId': characterId,
    'hpAfter': hpAfter,
    'injuries': [for (final injury in injuries) injury.name],
    'consumablesUsed': [
      for (final MapEntry(key: item, value: quantity)
          in consumablesUsed.entries)
        if (quantity > 0) {'item': item, 'quantity': quantity},
    ],
    'spellsUsed': [
      for (final MapEntry(key: spell, value: usages) in spellsUsed.entries)
        if (usages > 0) {'spell': spell, 'usages': usages},
    ],
  };

  @override
  List<Object?> get props => [
    characterId,
    hpAfter,
    injuries,
    consumablesUsed,
    spellsUsed,
  ];
}

/// Scontro della sezione `fights` (sostituita per intero a ogni salvataggio).
class MissionFightInput extends Equatable {
  const MissionFightInput({required this.enemies, this.corrections});

  final List<MissionEnemyInput> enemies;

  /// `null` = nessuna correzione; altrimenti la lista completa (BE handoff).
  final List<MissionCorrection>? corrections;

  Map<String, dynamic> toJson() => {
    'enemies': [for (final enemy in enemies) enemy.toJson()],
    if (corrections case final corrections?)
      'corrections': [
        for (final correction in corrections) correction.toJson(),
      ],
  };

  @override
  List<Object?> get props => [enemies, corrections];
}

/// Premio di un personaggio (`MissionPrizeInput`): monete e xp liberi ≥ 0
/// (D-15), oggetti dal catalogo servito, un compagno e una magia al massimo,
/// la cura del blocco tenuta o tolta (D-22). Il BE rivalida.
class MissionPrizeInput extends Equatable {
  const MissionPrizeInput({
    required this.characterId,
    required this.coins,
    required this.xp,
    required this.cure,
    this.items = const [],
    this.petId,
    this.spellId,
  });

  factory MissionPrizeInput.of(MissionPrize prize) => MissionPrizeInput(
    characterId: prize.characterId,
    coins: prize.coins,
    xp: prize.xp,
    cure: prize.cure != null,
    items: List.unmodifiable(prize.items),
    petId: prize.petId,
    spellId: prize.spellId,
  );

  final String characterId;
  final Coins coins;
  final int xp;
  final bool cure;
  final List<MissionPrizeItem> items;
  final String? petId;
  final String? spellId;

  MissionPrizeInput withCoins(Coins coins) => _copy(
    coins: Coins(
      gold: math.max(0, coins.gold),
      silver: math.max(0, coins.silver),
      copper: math.max(0, coins.copper),
    ),
  );

  MissionPrizeInput withXp(int xp) => _copy(xp: math.max(0, xp));

  MissionPrizeInput withItemAdded(String itemId) {
    final current = _itemOf(itemId);
    if (current != null) return withItemQuantity(itemId, current.quantity + 1);
    return _copy(
      items: [
        ...items,
        MissionPrizeItem(itemId: itemId, quantity: 1),
      ],
    );
  }

  MissionPrizeInput withItemQuantity(String itemId, int quantity) {
    final bounded = quantity.clamp(1, maxPrizeItemQuantity);
    return _copy(
      items: [
        for (final item in items)
          item.itemId == itemId
              ? MissionPrizeItem(itemId: itemId, quantity: bounded)
              : item,
      ],
    );
  }

  MissionPrizeInput withoutItem(String itemId) =>
      _copy(items: items.where((item) => item.itemId != itemId).toList());

  MissionPrizeInput withPet(String? petId) => _copy(petId: () => petId);

  MissionPrizeInput withSpell(String? spellId) => _copy(spellId: () => spellId);

  MissionPrizeInput withoutCure() => _copy(cure: false);

  MissionPrizeItem? _itemOf(String itemId) {
    for (final item in items) {
      if (item.itemId == itemId) return item;
    }
    return null;
  }

  MissionPrizeInput _copy({
    Coins? coins,
    int? xp,
    bool? cure,
    List<MissionPrizeItem>? items,
    String? Function()? petId,
    String? Function()? spellId,
  }) => MissionPrizeInput(
    characterId: characterId,
    coins: coins ?? this.coins,
    xp: xp ?? this.xp,
    cure: cure ?? this.cure,
    items: List.unmodifiable(items ?? this.items),
    petId: petId == null ? this.petId : petId(),
    spellId: spellId == null ? this.spellId : spellId(),
  );

  Map<String, dynamic> toJson() => {
    'characterId': characterId,
    'coins': coins.toJson(),
    'cure': cure,
    'items': [for (final item in items) item.toJson()],
    'pet': petId,
    'spell': spellId,
    'xp': xp,
  };

  @override
  List<Object?> get props => [
    characterId,
    coins,
    xp,
    cure,
    items,
    petId,
    spellId,
  ];
}

/// `saveMissionDraft`: manda solo le sezioni presenti (D-18).
class SaveMissionDraftInput extends Equatable {
  const SaveMissionDraftInput({
    required this.pendingQuestId,
    this.step,
    this.placeId,
    this.fights,
    this.prizes,
  });

  final String pendingQuestId;
  final MissionDraftStep? step;
  final String? placeId;
  final List<MissionFightInput>? fights;
  final List<MissionPrizeInput>? prizes;

  Map<String, dynamic> toJson() => {
    'pendingQuestId': pendingQuestId,
    if (step case final step?) 'step': step.name,
    if (placeId case final placeId?) 'place': placeId,
    if (fights case final fights?)
      'fights': [for (final fight in fights) fight.toJson()],
    if (prizes case final prizes?)
      'prizes': [for (final prize in prizes) prize.toJson()],
  };

  @override
  List<Object?> get props => [pendingQuestId, step, placeId, fights, prizes];
}

/// `simulateMissionFight`: lo scontro [fightIndex] coi suoi nemici (D-02, D-24).
class SimulateMissionFightInput extends Equatable {
  const SimulateMissionFightInput({
    required this.pendingQuestId,
    required this.fightIndex,
    required this.enemies,
  });

  final String pendingQuestId;
  final int fightIndex;
  final List<MissionEnemyInput> enemies;

  Map<String, dynamic> toJson() => {
    'pendingQuestId': pendingQuestId,
    'fightIndex': fightIndex,
    'enemies': [for (final enemy in enemies) enemy.toJson()],
  };

  @override
  List<Object?> get props => [pendingQuestId, fightIndex, enemies];
}

/// Sezione `fights` ricostruita dalla bozza servita: nemici serviti; per uno scontro con almeno un `corrected` la lista COMPLETA, una correzione per partecipante dall'effetto `effective` (corrected ?? simulated), sempre con `hpAfter` (regola del handoff BE).
List<MissionFightInput> fightsInputOf(MissionDraft draft) => List.unmodifiable([
  for (final fight in draft.fights)
    MissionFightInput(
      enemies: _enemiesOf(fight),
      corrections: _servedCorrectionsOf(fight),
    ),
]);

/// Nemici nuovi per ogni scontro, nessuna correzione: il BE tiene quelle del prefisso invariato e invalida dal primo scontro cambiato (D-24).
List<MissionFightInput> fightsInputWithEnemies(
  MissionDraft draft,
  List<List<MissionEnemyInput>> enemiesPerFight,
) => List.unmodifiable([
  for (final enemies in enemiesPerFight)
    MissionFightInput(enemies: List.unmodifiable(enemies)),
]);

/// Correzioni del solo scontro [fightIndex], sempre la lista completa (un partecipante assente da [corrections] è completato dal suo `effective` servito); gli altri scontri vanno senza correzioni, cioè invariati sul BE, che invalida da sé i successivi (D-24, D-31).
List<MissionFightInput> fightsInputWithCorrections(
  MissionDraft draft,
  int fightIndex,
  List<MissionCorrection> corrections,
) => List.unmodifiable([
  for (final (index, fight) in draft.fights.indexed)
    MissionFightInput(
      enemies: _enemiesOf(fight),
      corrections: index == fightIndex
          ? _completedCorrections(fight, corrections)
          : null,
    ),
]);

List<MissionEnemyInput> _enemiesOf(MissionFight fight) =>
    List.unmodifiable(fight.enemies.map(MissionEnemyInput.of));

List<MissionCorrection>? _servedCorrectionsOf(MissionFight fight) {
  final isCorrected = fight.outcomes.any(
    (outcome) => outcome.corrected != null,
  );
  if (!isCorrected) return null;
  return _completedCorrections(fight, const []);
}

/// Una correzione per ogni esito servito (quella data o l'effetto servito), poi
/// le correzioni date per personaggi senza esito servito.
List<MissionCorrection> _completedCorrections(
  MissionFight fight,
  List<MissionCorrection> given,
) {
  final byCharacter = {
    for (final correction in given) correction.characterId: correction,
  };
  final servedIds = {for (final outcome in fight.outcomes) outcome.characterId};
  return List.unmodifiable([
    for (final outcome in fight.outcomes)
      byCharacter[outcome.characterId] ?? _servedCorrectionOf(outcome),
    ...given.where((correction) => !servedIds.contains(correction.characterId)),
  ]);
}

/// Senza effetto servito il personaggio resta com'era all'inizio dello scontro.
MissionCorrection _servedCorrectionOf(MissionFightOutcome outcome) =>
    MissionCorrection.fromEffects(
      outcome.characterId,
      outcome.effective ?? MissionFightEffects(hpAfter: outcome.hpBefore),
    );
