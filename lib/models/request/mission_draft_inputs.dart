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
    this.companionLifeAfter,
    this.injuriesRemoved = const [],
    this.declaresRemovals = false,
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
    companionLifeAfter: effects.companionLifeAfter,
    injuriesRemoved: List.unmodifiable(effects.injuriesRemoved),
  );

  final String characterId;
  final int hpAfter;

  /// Tutte le ferite che lo scontro aggiunge dopo la correzione (D-14).
  final List<InjuryType> injuries;

  /// Id dell'oggetto → quantità usata.
  final Map<String, int> consumablesUsed;

  /// Id della magia → usi consumati.
  final Map<String, int> spellsUsed;

  /// `null` = nessun compagno nello scontro: la chiave non parte (D-33).
  final int? companionLifeAfter;

  /// Ferite già portate che la correzione toglie (Phase 24 D-13).
  final List<InjuryType> injuriesRemoved;

  /// Vero = `injuriesRemoved` parte sempre, anche vuota; falso = parte solo
  /// se ne porta (il BE di oggi non riceve la chiave).
  final bool declaresRemovals;

  MissionCorrection withHp(int hp) => _copy(hpAfter: hp);

  MissionCorrection withInjuryToggled(InjuryType injury) => _copy(
    injuries: injuries.contains(injury)
        ? _without(injuries, injury)
        : [...injuries, injury],
  );

  /// Togliere il segno a una ferita tolta la leva anche dalle aggiunte
  /// (Phase 24 D-16).
  MissionCorrection withInjuryRemovalToggled(InjuryType injury) {
    if (!injuriesRemoved.contains(injury)) {
      return _copy(injuriesRemoved: [...injuriesRemoved, injury]);
    }
    return _copy(
      injuriesRemoved: _without(injuriesRemoved, injury),
      injuries: _without(injuries, injury),
    );
  }

  MissionCorrection withRemovalsDeclared() => _copy(declaresRemovals: true);

  MissionCorrection withConsumableUsed(String itemId, int quantity) =>
      _copy(consumablesUsed: {...consumablesUsed, itemId: quantity});

  MissionCorrection withSpellUsed(String spellId, int usages) =>
      _copy(spellsUsed: {...spellsUsed, spellId: usages});

  MissionCorrection withCompanionLife(int life) =>
      _copy(companionLifeAfter: life);

  MissionCorrection _copy({
    int? hpAfter,
    List<InjuryType>? injuries,
    Map<String, int>? consumablesUsed,
    Map<String, int>? spellsUsed,
    int? companionLifeAfter,
    List<InjuryType>? injuriesRemoved,
    bool? declaresRemovals,
  }) => MissionCorrection(
    characterId: characterId,
    hpAfter: hpAfter ?? this.hpAfter,
    injuries: List.unmodifiable(injuries ?? this.injuries),
    consumablesUsed: Map.unmodifiable(consumablesUsed ?? this.consumablesUsed),
    spellsUsed: Map.unmodifiable(spellsUsed ?? this.spellsUsed),
    companionLifeAfter: companionLifeAfter ?? this.companionLifeAfter,
    injuriesRemoved: List.unmodifiable(injuriesRemoved ?? this.injuriesRemoved),
    declaresRemovals: declaresRemovals ?? this.declaresRemovals,
  );

  static List<InjuryType> _without(
    List<InjuryType> injuries,
    InjuryType injury,
  ) => injuries.where((existing) => existing != injury).toList();

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
    if (companionLifeAfter case final life?) 'companionLifeAfter': life,
    if (declaresRemovals || injuriesRemoved.isNotEmpty)
      'injuriesRemoved': [for (final injury in injuriesRemoved) injury.name],
  };

  @override
  List<Object?> get props => [
    characterId,
    hpAfter,
    injuries,
    consumablesUsed,
    spellsUsed,
    companionLifeAfter,
    injuriesRemoved,
    declaresRemovals,
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
        MissionPrizeItem(itemId: itemId, quantity: minPrizeItemQuantity),
      ],
    );
  }

  MissionPrizeInput withItemQuantity(String itemId, int quantity) {
    final bounded = quantity.clamp(minPrizeItemQuantity, maxPrizeItemQuantity);
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

  MissionPrizeInput withCure() => _copy(cure: true);

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

/// Aggiunta alla storia di un partecipante (`backgroundAdditions` del
/// salvataggio): un testo vuoto toglie l'aggiunta di quel personaggio.
class MissionBackgroundAdditionInput extends Equatable {
  const MissionBackgroundAdditionInput({
    required this.characterId,
    required this.text,
  });

  final String characterId;
  final String text;

  Map<String, dynamic> toJson() => {'characterId': characterId, 'text': text};

  @override
  List<Object?> get props => [characterId, text];
}

/// `saveMissionDraft`: manda solo le sezioni presenti (D-18).
class SaveMissionDraftInput extends Equatable {
  const SaveMissionDraftInput({
    required this.pendingQuestId,
    this.step,
    this.placeId,
    this.fights,
    this.prizes,
    this.backgroundAdditions,
  });

  final String pendingQuestId;
  final MissionDraftStep? step;
  final String? placeId;
  final List<MissionFightInput>? fights;
  final List<MissionPrizeInput>? prizes;

  /// `null` = aggiunte non toccate (Phase 24 D-05).
  final List<MissionBackgroundAdditionInput>? backgroundAdditions;

  Map<String, dynamic> toJson() => {
    'pendingQuestId': pendingQuestId,
    if (step case final step?) 'step': step.name,
    if (placeId case final placeId?) 'place': placeId,
    if (fights case final fights?)
      'fights': [for (final fight in fights) fight.toJson()],
    if (prizes case final prizes?)
      'prizes': [for (final prize in prizes) prize.toJson()],
    if (backgroundAdditions case final additions?)
      'backgroundAdditions': [
        for (final addition in additions) addition.toJson(),
      ],
  };

  @override
  List<Object?> get props => [
    pendingQuestId,
    step,
    placeId,
    fights,
    prizes,
    backgroundAdditions,
  ];
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

/// Nemici nuovi per ogni scontro, nessuna correzione: il BE tiene quelle del prefisso invariato e invalida dal primo scontro cambiato (D-24).
List<MissionFightInput> fightsInputWithEnemies(
  List<List<MissionEnemyInput>> enemiesPerFight,
) => List.unmodifiable([
  for (final enemies in enemiesPerFight)
    MissionFightInput(enemies: List.unmodifiable(enemies)),
]);

/// Un'aggiunta per partecipante, nell'ordine dei partecipanti, col testo senza
/// spazi ai bordi: anche le vuote partono, perché tolgono l'aggiunta salvata
/// (Phase 24 D-06).
List<MissionBackgroundAdditionInput> backgroundAdditionsInputOf(
  List<MissionParticipant> participants,
  Map<String, String> textsByCharacterId,
) => List.unmodifiable([
  for (final participant in participants)
    MissionBackgroundAdditionInput(
      characterId: participant.characterId,
      text: (textsByCharacterId[participant.characterId] ?? '').trim(),
    ),
]);

/// Correzioni del solo scontro [fightIndex], sempre la lista completa (un partecipante assente da [corrections] è completato dal suo `effective` servito); gli altri scontri vanno senza correzioni, cioè invariati sul BE, che invalida da sé i successivi (D-24, D-31). Con [declaresRemovals] ogni correzione dello scontro manda le sue ferite tolte, anche nessuna (Phase 24 Q7).
List<MissionFightInput> fightsInputWithCorrections(
  MissionDraft draft,
  int fightIndex,
  List<MissionCorrection> corrections, {
  bool declaresRemovals = false,
}) => List.unmodifiable([
  for (final (index, fight) in draft.fights.indexed)
    MissionFightInput(
      enemies: _enemiesOf(fight),
      corrections: index == fightIndex
          ? _correctionsOf(
              fight,
              corrections,
              declaresRemovals: declaresRemovals,
            )
          : null,
    ),
]);

List<MissionCorrection> _correctionsOf(
  MissionFight fight,
  List<MissionCorrection> given, {
  required bool declaresRemovals,
}) {
  final completed = _completedCorrections(fight, given);
  if (!declaresRemovals) return completed;
  return List.unmodifiable(
    completed.map((correction) => correction.withRemovalsDeclared()),
  );
}

List<MissionEnemyInput> _enemiesOf(MissionFight fight) =>
    List.unmodifiable(fight.enemies.map(MissionEnemyInput.of));

/// Una correzione per ogni esito servito: quella data o l'effetto servito.
List<MissionCorrection> _completedCorrections(
  MissionFight fight,
  List<MissionCorrection> given,
) {
  final byCharacter = {
    for (final correction in given) correction.characterId: correction,
  };
  return List.unmodifiable([
    for (final outcome in fight.outcomes)
      byCharacter[outcome.characterId] ?? _servedCorrectionOf(outcome),
  ]);
}

/// Senza effetto servito il personaggio resta com'era all'inizio dello scontro.
MissionCorrection _servedCorrectionOf(MissionFightOutcome outcome) =>
    MissionCorrection.fromEffects(
      outcome.characterId,
      outcome.effective ?? MissionFightEffects(hpAfter: outcome.hpBefore),
    );
