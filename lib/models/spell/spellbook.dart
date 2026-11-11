import 'dart:math';

import 'package:equatable/equatable.dart';
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
    required int this.usages,
    required this.isPending,
  });

  final Spell? spell;
  final int? usages;
  final bool isPending;

  bool get isEmpty => spell == null;

  @override
  List<Object?> get props => [spell, usages, isPending];
}

/// Una magia conosciuta nella lista, nell'ordine degli stati del BE.
class SpellbookEntry extends Equatable {
  const SpellbookEntry({
    required this.spell,
    required this.usages,
    required this.isActive,
    required this.isPending,
    required this.recoveries,
  });

  final Spell spell;
  final int usages;
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
    final states = _firstStatePerSpell(character?.status?.spellStates);
    final slotCount = max(0, character?.status?.maxActiveSpells ?? 0);

    bool isActive(SpellState state) => switch (pending[state.spellId]) {
      SpellOperation.equip => true,
      SpellOperation.unequip => false,
      null => state.active,
    };
    final active = [
      for (final state in states)
        if (isActive(state)) state,
    ];

    SpellSlot slotAt(int index) {
      if (index >= active.length) return const SpellSlot.empty();
      final state = active[index];
      return SpellSlot.filled(
        spell: state.spell,
        usages: state.usages,
        isPending: pending.containsKey(state.spellId),
      );
    }

    return Spellbook._(
      isVisible: states.isNotEmpty || slotCount > 0,
      slotCount: slotCount,
      slots: List.unmodifiable(List.generate(slotCount, slotAt)),
      entries: List.unmodifiable(
        states.map(
          (state) => SpellbookEntry(
            spell: state.spell,
            usages: state.usages,
            isActive: isActive(state),
            isPending: pending.containsKey(state.spellId),
            recoveries: state.recoveries,
          ),
        ),
      ),
      activeSpellIds: List.unmodifiable(active.map((state) => state.spellId)),
      pending: Map.unmodifiable(pending),
    );
  }

  final bool isVisible;
  final int slotCount;
  final List<SpellSlot> slots;
  final List<SpellbookEntry> entries;

  /// Slot nell'ordine degli stati (apprendimento), per il server e per
  /// l'overlay: stati `active` − unequip in attesa + equip in attesa.
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

  /// Una magia compare una volta sola: a parità di id vale il primo stato.
  static List<SpellState> _firstStatePerSpell(List<SpellState>? states) {
    final byId = <String, SpellState>{};
    for (final state in states ?? const <SpellState>[]) {
      byId.putIfAbsent(state.spellId, () => state);
    }
    return byId.values.toList();
  }

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
