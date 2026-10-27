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

  /// Ultimo personaggio visto (tap o subscription): una risposta riuscita
  /// chiude subito l'operazione se il BE l'ha già riflessa.
  Character? _latest;
  int _nextToken = 0;
  int _sequence = 0;

  /// Token dell'operazione corrente per magia: le risposte di operazioni già
  /// chiuse (subscription, errore, timeout) vengono ignorate.
  final Map<String, int> _tokens = {};
  final Map<String, Timer> _timers = {};

  /// Richieste riuscite in attesa di `characterUpdated`: mai stato dalla
  /// risposta della mutation (D-16).
  final Set<String> _succeeded = {};

  /// Calcolato sulla vista ottimistica e restituito subito: il widget lo usa
  /// per l'aptica (D-08).
  SpellToggleIntent toggle(Character character, String spellId) {
    _latest = character;
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
    _latest = character;
    final matched = [
      for (final MapEntry(key: spellId, value: operation)
          in state.pending.entries)
        if (_matches(character, spellId, operation)) spellId,
    ];
    if (matched.isEmpty) return;
    matched.forEach(_forget);
    emit(state.copyWith(pending: _pendingWithout(matched)));
  }

  @override
  Future<void> close() {
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
    _tokens.clear();
    _succeeded.clear();
    return super.close();
  }

  void _start(String characterId, String spellId, SpellOperation operation) {
    final token = ++_nextToken;
    _tokens[spellId] = token;
    _timers[spellId] = Timer(
      settleTimeout,
      () => _onSettleTimeout(spellId, operation, token),
    );
    emit(
      state.copyWith(
        pending: Map.unmodifiable({...state.pending, spellId: operation}),
      ),
    );
    unawaited(
      _send(
        characterId: characterId,
        spellId: spellId,
        operation: operation,
        token: token,
      ),
    );
  }

  Future<void> _send({
    required String characterId,
    required String spellId,
    required SpellOperation operation,
    required int token,
  }) async {
    try {
      await (operation == SpellOperation.equip
          ? _repository.equip(characterId: characterId, spellId: spellId)
          : _repository.unequip(characterId: characterId, spellId: spellId));
      _succeed(spellId, operation, token);
    } on SpellEquipException catch (error) {
      _fail(spellId, operation, token, error.failure);
    } on Object {
      _fail(spellId, operation, token, SpellEquipFailure.unknown);
    }
  }

  void _succeed(String spellId, SpellOperation operation, int token) {
    if (_tokens[spellId] != token) return;
    final latest = _latest;
    if (latest != null && _matches(latest, spellId, operation)) {
      _settle(spellId);
      return;
    }
    _succeeded.add(spellId);
  }

  void _onSettleTimeout(String spellId, SpellOperation operation, int token) {
    if (_tokens[spellId] != token) return;
    if (_succeeded.contains(spellId)) {
      _settle(spellId);
      return;
    }
    _fail(spellId, operation, token, SpellEquipFailure.timedOut);
  }

  void _settle(String spellId) {
    _forget(spellId);
    emit(state.copyWith(pending: _pendingWithout([spellId])));
  }

  void _fail(
    String spellId,
    SpellOperation operation,
    int token,
    SpellEquipFailure failure,
  ) {
    if (_tokens[spellId] != token) return;
    _forget(spellId);
    emit(
      SpellsState(
        pending: _pendingWithout([spellId]),
        outcome: SpellOutcome(
          sequence: ++_sequence,
          spellId: spellId,
          operation: operation,
          kind: SpellOutcomeKind.failed,
          failure: failure,
        ),
      ),
    );
  }

  void _forget(String spellId) {
    _tokens.remove(spellId);
    _timers.remove(spellId)?.cancel();
    _succeeded.remove(spellId);
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
