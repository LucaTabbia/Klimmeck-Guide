import 'dart:math';

import 'package:equatable/equatable.dart';
import 'package:klimmeck_guide/models/active_spell.dart';
import 'package:klimmeck_guide/models/character/character.dart';
import 'package:klimmeck_guide/models/spell.dart';
import 'package:klimmeck_guide/models/spell/spell_state.dart';

/// Operazione in attesa su una magia (overlay ottimistico, D-16).
enum SpellOperation { equip, unequip }

/// Cosa fa un tap su una magia (D-06, D-07, D-11, D-16), calcolato sulla vista ottimistica.
enum SpellToggleIntent {
  equip,
  unequip,
  blockedSlotsFull,
  blockedNoSlots,
  ignoredPending,
  ignoredUnknown,
}

/// Uno slot della riga magie attive: vuoto o occupato da una magia (D-10).
class SpellSlot extends Equatable {
  const SpellSlot.empty() : spell = null, usages = null, isPending = false;

  const SpellSlot.filled({
    required Spell this.spell,
    required this.usages,
    required this.isPending,
  });

  final Spell? spell;
  final int? usages;
  final bool isPending;

  bool get isEmpty => spell == null;

  @override
  List<Object?> get props => [spell, usages, isPending];
}

/// Una magia conosciuta nella lista, nell'ordine del BE (D-14, D-15).
class SpellbookEntry extends Equatable {
  const SpellbookEntry({
    required this.spell,
    required this.usages,
    required this.isActive,
    required this.isPending,
    required this.recoveries,
  });

  final Spell spell;
  final int? usages;
  final bool isActive;
  final bool isPending;
  final List<DateTime> recoveries;

  @override
  List<Object?> get props => [spell, usages, isActive, isPending, recoveries];
}

/// Vista pura della sezione Magie (D-02, D-10..D-16): nessun widget calcola stato.
class Spellbook extends Equatable {
  const Spellbook._({
    required this.isVisible,
    required this.slotCount,
    required this.slots,
    required this.entries,
    required this.activeSpellIds,
    required this.pending,
  });

  factory Spellbook.of(
    Character? character, {
    Map<String, SpellOperation> pending = const {},
  }) {
    final spells = character?.status?.spells ?? const <Spell>[];
    final slotCount = max(0, character?.status?.maxActiveSpells ?? 0);
    final statesById = {
      for (final state
          in character?.status?.spellStates ?? const <SpellState>[])
        state.spellId: state,
    };
    final serverActiveById = _serverActiveById(character);
    final optimisticById = _optimisticActiveById(
      serverActiveById: serverActiveById,
      knownById: {for (final spell in spells) spell.id: spell},
      pending: pending,
    );
    final active = optimisticById.values.toList();

    SpellSlot slotAt(int index) {
      if (index >= active.length) return const SpellSlot.empty();
      final spell = active[index];
      return SpellSlot.filled(
        spell: spell,
        usages: _usagesOf(
          spell,
          statesById[spell.id],
          serverActiveById[spell.id],
        ),
        isPending: pending.containsKey(spell.id),
      );
    }

    return Spellbook._(
      isVisible: spells.isNotEmpty || slotCount > 0,
      slotCount: slotCount,
      slots: List.unmodifiable(List.generate(slotCount, slotAt)),
      entries: List.unmodifiable(
        spells.map(
          (spell) => SpellbookEntry(
            spell: spell,
            usages: _usagesOf(
              spell,
              statesById[spell.id],
              serverActiveById[spell.id],
            ),
            isActive: optimisticById.containsKey(spell.id),
            isPending: pending.containsKey(spell.id),
            recoveries: statesById[spell.id]?.recoveries ?? const [],
          ),
        ),
      ),
      activeSpellIds: List.unmodifiable(optimisticById.keys),
      pending: Map.unmodifiable(pending),
    );
  }

  final bool isVisible;
  final int slotCount;
  final List<SpellSlot> slots;
  final List<SpellbookEntry> entries;

  /// Ordine ottimistico degli slot (server − unequip in attesa + equip in attesa).
  final List<String> activeSpellIds;
  final Map<String, SpellOperation> pending;

  SpellbookEntry? entryFor(String spellId) {
    for (final entry in entries) {
      if (entry.spell.id == spellId) return entry;
    }
    return null;
  }

  SpellToggleIntent intentFor(String spellId) {
    if (pending.containsKey(spellId)) return SpellToggleIntent.ignoredPending;
    if (activeSpellIds.contains(spellId)) return SpellToggleIntent.unequip;
    if (entryFor(spellId) == null) return SpellToggleIntent.ignoredUnknown;
    if (slotCount == 0) return SpellToggleIntent.blockedNoSlots;
    if (activeSpellIds.length >= slotCount) {
      return SpellToggleIntent.blockedSlotsFull;
    }
    return SpellToggleIntent.equip;
  }

  /// Magie attive lato server con `spell` valorizzata, nell'ordine del BE (F6).
  static Map<String, ActiveSpell> _serverActiveById(Character? character) {
    final byId = <String, ActiveSpell>{};
    for (final active in character?.assets?.activeSpells ?? const []) {
      final spell = active.spell;
      if (spell == null) continue;
      byId.putIfAbsent(spell.id, () => active);
    }
    return byId;
  }

  /// Server − unequip in attesa + equip in attesa (nell'ordine dei tap): stesso
  /// ordine che il BE conferma (`$push` / `$pull`).
  static Map<String, Spell> _optimisticActiveById({
    required Map<String, ActiveSpell> serverActiveById,
    required Map<String, Spell> knownById,
    required Map<String, SpellOperation> pending,
  }) {
    final byId = <String, Spell>{
      for (final MapEntry(key: id, value: active) in serverActiveById.entries)
        if (pending[id] != SpellOperation.unequip)
          if (active.spell case final spell?) id: spell,
    };
    for (final MapEntry(key: id, value: operation) in pending.entries) {
      final spell = knownById[id];
      if (operation != SpellOperation.equip || spell == null) continue;
      byId.putIfAbsent(id, () => spell);
    }
    return byId;
  }

  /// Tabella di fallback (D-03): stato 9.1, poi usi attivi, poi catalogo.
  static int? _usagesOf(Spell spell, SpellState? state, ActiveSpell? active) =>
      state?.usages ?? active?.usages ?? spell.maxUsages;

  @override
  List<Object?> get props => [
    isVisible,
    slotCount,
    slots,
    entries,
    activeSpellIds,
    pending,
  ];
}
