import 'dart:math' show max;

import 'package:equatable/equatable.dart';
import 'package:klimmeck_guide/models/asset_quantity.dart';
import 'package:klimmeck_guide/models/character/character.dart';
import 'package:klimmeck_guide/models/enums/injury_type.dart';
import 'package:klimmeck_guide/models/request/participant_override.dart';
import 'package:klimmeck_guide/models/spell/spellbook.dart';

/// Consumabile posseduto (loot) con la quantità che il GM segna come usata, `0..owned`.
class ConsumableLine extends Equatable {
  const ConsumableLine({
    required this.itemId,
    required this.name,
    required this.owned,
    required this.used,
  });

  final String itemId;
  final String? name;
  final int owned;
  final int used;

  ConsumableLine copyWith({required int used}) =>
      ConsumableLine(itemId: itemId, name: name, owned: owned, used: used);

  @override
  List<Object?> get props => [itemId, name, owned, used];
}

/// Magia attiva con gli usi che il GM segna come consumati, `0..remaining`.
class SpellLine extends Equatable {
  const SpellLine({
    required this.spellId,
    required this.name,
    required this.remaining,
    required this.used,
  });

  final String spellId;
  final String? name;
  final int remaining;
  final int used;

  SpellLine copyWith({required int used}) =>
      SpellLine(spellId: spellId, name: name, remaining: remaining, used: used);

  @override
  List<Object?> get props => [spellId, name, remaining, used];
}

/// Valori del form per un partecipante (10-CONTEXT D-11/D-12): i default significano «nessun cambiamento»; i limiti rispecchiano quelli del BE (C1), che resta giudice (OUTCOME_OVERRIDE_INVALID).
class ParticipantDraft extends Equatable {
  const ParticipantDraft({
    required this.characterId,
    required this.name,
    required this.currentLifePoints,
    required this.maxLifePoints,
    required this.hpAfter,
    required this.existingInjuries,
    required this.addedInjuries,
    required this.consumables,
    required this.spells,
  });

  factory ParticipantDraft.from(
    Character character, {
    required String fallbackName,
  }) {
    final status = character.status;
    final maxLifePoints = max(1, status?.maxLifePoints ?? 1);
    final currentLifePoints = (status?.currentLifePoints ?? maxLifePoints)
        .clamp(1, maxLifePoints);
    return ParticipantDraft(
      characterId: character.id,
      name: character.infos?.name ?? fallbackName,
      currentLifePoints: currentLifePoints,
      maxLifePoints: maxLifePoints,
      hpAfter: currentLifePoints,
      existingInjuries: List.unmodifiable(status?.injuries ?? const []),
      addedInjuries: const [],
      consumables: List.unmodifiable(
        (character.assets?.ownedItems ?? const <AssetQuantity>[])
            .where(_isUsableLoot)
            .map(
              (owned) => ConsumableLine(
                itemId: owned.item!.id,
                name: owned.item!.name,
                owned: owned.quantity!,
                used: 0,
              ),
            ),
      ),
      spells: List.unmodifiable(
        Spellbook.of(character).slots
            .where((slot) => !slot.isEmpty)
            .map(
              (slot) => SpellLine(
                spellId: slot.spell!.id,
                name: slot.spell!.name,
                remaining: slot.usages ?? 0,
                used: 0,
              ),
            ),
      ),
    );
  }

  final String characterId;
  final String name;
  final int currentLifePoints;
  final int maxLifePoints;
  final int hpAfter;
  final List<InjuryType> existingInjuries;

  /// Solo le ferite nuove, nell'ordine di `InjuryType.values`.
  final List<InjuryType> addedInjuries;
  final List<ConsumableLine> consumables;
  final List<SpellLine> spells;

  bool get canEditHp => maxLifePoints > 1;

  ParticipantDraft withHp(int value) =>
      _copyWith(hpAfter: value.clamp(1, maxLifePoints));

  ParticipantDraft withInjuryToggled(InjuryType injury) {
    if (existingInjuries.contains(injury)) return this;
    final added = addedInjuries.contains(injury)
        ? addedInjuries.where((existing) => existing != injury)
        : [...addedInjuries, injury];
    return _copyWith(
      addedInjuries: List.unmodifiable(InjuryType.values.where(added.contains)),
    );
  }

  ParticipantDraft withConsumableUsed(String itemId, int used) => _copyWith(
    consumables: List.unmodifiable(
      consumables.map(
        (line) => line.itemId == itemId
            ? line.copyWith(used: used.clamp(0, line.owned))
            : line,
      ),
    ),
  );

  ParticipantDraft withSpellUsed(String spellId, int used) => _copyWith(
    spells: List.unmodifiable(
      spells.map(
        (line) => line.spellId == spellId
            ? line.copyWith(used: used.clamp(0, line.remaining))
            : line,
      ),
    ),
  );

  /// `null` quando il GM non ha cambiato nulla: il partecipante è omesso dall'input.
  /// Non `override`: oscurerebbe l'annotazione `@override` dentro la classe.
  ParticipantOverride? get asOverride {
    final hpChanged = hpAfter != currentLifePoints;
    final consumablesUsed = {
      for (final line in consumables)
        if (line.used >= 1) line.itemId: line.used,
    };
    final spellsUsed = {
      for (final line in spells)
        if (line.used >= 1) line.spellId: line.used,
    };
    if (!hpChanged &&
        addedInjuries.isEmpty &&
        consumablesUsed.isEmpty &&
        spellsUsed.isEmpty) {
      return null;
    }
    return ParticipantOverride(
      characterId: characterId,
      hpAfter: hpChanged ? hpAfter : null,
      injuries: addedInjuries,
      consumablesUsed: consumablesUsed,
      spellsUsed: spellsUsed,
    );
  }

  static bool _isUsableLoot(AssetQuantity owned) =>
      owned.item?.isLoot == true && (owned.quantity ?? 0) > 0;

  ParticipantDraft _copyWith({
    int? hpAfter,
    List<InjuryType>? addedInjuries,
    List<ConsumableLine>? consumables,
    List<SpellLine>? spells,
  }) => ParticipantDraft(
    characterId: characterId,
    name: name,
    currentLifePoints: currentLifePoints,
    maxLifePoints: maxLifePoints,
    hpAfter: hpAfter ?? this.hpAfter,
    existingInjuries: existingInjuries,
    addedInjuries: addedInjuries ?? this.addedInjuries,
    consumables: consumables ?? this.consumables,
    spells: spells ?? this.spells,
  );

  @override
  List<Object?> get props => [
    characterId,
    name,
    currentLifePoints,
    maxLifePoints,
    hpAfter,
    existingInjuries,
    addedInjuries,
    consumables,
    spells,
  ];
}

/// Override dei soli partecipanti cambiati, nell'ordine del form.
List<ParticipantOverride> overridesOf(List<ParticipantDraft> drafts) =>
    List.unmodifiable(drafts.map((draft) => draft.asOverride).nonNulls);
