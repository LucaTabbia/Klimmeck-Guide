import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/models/character/character.dart';
import 'package:klimmeck_guide/models/spell/spellbook.dart';
import 'package:klimmeck_guide/repository/spell_equip_failure.dart';
import 'package:klimmeck_guide/repository/spells_repository.dart';
import 'package:klimmeck_guide/shared/bloc/safe_emit.dart';

part 'spells_state.dart';

/// Equip/disequip ottimistici (D-16): un'operazione in attesa per magia,
/// chiusa dalla subscription, da un errore o dopo [settleTimeout]. Fornito da
/// `AuthenticatedShell` (il PageView distrugge le tab fuori schermo, F3).
class SpellsCubit extends Cubit<SpellsState> with SafeEmit<SpellsState> {
  SpellsCubit(this._repository, {this.settleTimeout = defaultSettleTimeout})
    : super(const SpellsState());

  static const Duration defaultSettleTimeout = Duration(seconds: 15);

  final SpellsRepository _repository;
  final Duration settleTimeout;
  int _sequence = 0;

  /// Calcolato sulla vista ottimistica e restituito subito: il widget lo usa
  /// per l'aptica (D-08).
  SpellToggleIntent toggle(Character character, String spellId) {
    final intent = Spellbook.of(
      character,
      pending: state.pending,
    ).intentFor(spellId);
    switch (intent) {
      case SpellToggleIntent.equip:
        _start(character.id, spellId, SpellOperation.equip);
      case SpellToggleIntent.unequip:
        _start(character.id, spellId, SpellOperation.unequip);
      case SpellToggleIntent.blockedSlotsFull:
        _block(spellId, SpellOutcomeKind.blockedSlotsFull);
      case SpellToggleIntent.blockedNoSlots:
        _block(spellId, SpellOutcomeKind.blockedNoSlots);
      case SpellToggleIntent.ignoredPending:
      case SpellToggleIntent.ignoredUnknown:
        break;
    }
    return intent;
  }

  /// Ogni stato di `characterUpdated` chiude le operazioni che riflette.
  void sync(Character character) {
    final matched = [
      for (final MapEntry(key: spellId, value: operation)
          in state.pending.entries)
        if (_matches(character, spellId, operation)) spellId,
    ];
    if (matched.isEmpty) return;
    emit(state.copyWith(pending: _pendingWithout(matched)));
  }

  void _start(String characterId, String spellId, SpellOperation operation) {
    emit(
      state.copyWith(
        pending: Map.unmodifiable({...state.pending, spellId: operation}),
      ),
    );
    unawaited(
      _send(characterId: characterId, spellId: spellId, operation: operation),
    );
  }

  Future<void> _send({
    required String characterId,
    required String spellId,
    required SpellOperation operation,
  }) async {
    try {
      await (operation == SpellOperation.equip
          ? _repository.equip(characterId: characterId, spellId: spellId)
          : _repository.unequip(characterId: characterId, spellId: spellId));
    } on Object {
      return;
    }
  }

  void _block(String spellId, SpellOutcomeKind kind) => emit(
    state.copyWith(
      outcome: SpellOutcome(
        sequence: ++_sequence,
        spellId: spellId,
        operation: SpellOperation.equip,
        kind: kind,
      ),
    ),
  );

  Map<String, SpellOperation> _pendingWithout(Iterable<String> spellIds) =>
      Map.unmodifiable(
        Map.of(state.pending)..removeWhere((id, _) => spellIds.contains(id)),
      );

  static bool _matches(
    Character character,
    String spellId,
    SpellOperation operation,
  ) {
    final serverActiveIds = {
      for (final active in character.assets?.activeSpells ?? const [])
        if (active.spell case final spell?) spell.id,
    };
    final isActive = serverActiveIds.contains(spellId);
    return operation == SpellOperation.equip ? isActive : !isActive;
  }
}
