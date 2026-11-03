import 'dart:async';
import 'dart:collection';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/models/character/character.dart';
import 'package:klimmeck_guide/repository/companion_repository.dart';
import 'package:klimmeck_guide/repository/pet_equip_failure.dart';
import 'package:klimmeck_guide/shared/bloc/safe_emit.dart';

part 'companion_state.dart';

/// Slot «Compagno» ottimistico (D-10, schema Phase 8): una sola operazione
/// alla volta, chiusa dalla subscription, da un rifiuto o dopo
/// [settleTimeout]. Fornito da `AuthenticatedShell` (il PageView distrugge le
/// tab fuori schermo).
class CompanionCubit extends Cubit<CompanionState>
    with SafeEmit<CompanionState> {
  CompanionCubit(this._repository, {this.settleTimeout = defaultSettleTimeout})
    : super(const CompanionState());

  /// Stessa durata della richiesta: un solo valore da cambiare.
  static const Duration defaultSettleTimeout =
      CompanionRepository.defaultTimeout;

  final CompanionRepository _repository;
  final Duration settleTimeout;

  /// Ultimo personaggio visto: una risposta riuscita chiude subito
  /// l'operazione se il BE l'ha già riflessa. Lo aggiorna solo `sync`.
  Character? _latest;
  int _nextToken = 0;
  int _sequence = 0;

  /// Token dell'operazione corrente: le risposte di operazioni già chiuse
  /// (subscription, rifiuto, timeout, `close`) vengono ignorate.
  int? _token;
  Timer? _timer;

  /// Richiesta riuscita in attesa di `characterUpdated`: mai stato dalla
  /// risposta della mutation.
  bool _succeeded = false;

  final Queue<Future<void> Function()> _mutations = Queue();
  bool _isSending = false;

  /// Calcolato sulla vista ottimistica e restituito subito al widget.
  CompanionToggleIntent toggle(Character character, String petId) {
    _latest ??= character;
    if (state.pending != null) return CompanionToggleIntent.ignoredPending;
    final isDisplayed = state.displayedPetId(character) == petId;
    final operation = isDisplayed
        ? CompanionOperation.unequip
        : CompanionOperation.equip;
    _start(character.id, petId, operation);
    return isDisplayed
        ? CompanionToggleIntent.unequip
        : CompanionToggleIntent.equip;
  }

  /// Ogni stato di `characterUpdated` chiude l'operazione che riflette.
  void sync(Character character) {
    _latest = character;
    final pending = state.pending;
    if (pending == null || !_matches(character, pending)) return;
    _settle();
  }

  @override
  Future<void> close() {
    _forget();
    _mutations.clear();
    return super.close();
  }

  void _start(String characterId, String petId, CompanionOperation operation) {
    final token = ++_nextToken;
    final pending = PendingCompanion(petId: petId, operation: operation);
    _token = token;
    _succeeded = false;
    _timer = Timer(settleTimeout, () => _onSettleTimeout(pending, token));
    emit(CompanionState(pending: pending, outcome: state.outcome));
    _mutations.add(
      () => _send(characterId: characterId, pending: pending, token: token),
    );
    if (!_isSending) unawaited(_drainMutations());
  }

  Future<void> _drainMutations() async {
    _isSending = true;
    while (_mutations.isNotEmpty) {
      await _mutations.removeFirst()();
    }
    _isSending = false;
  }

  /// Un'operazione chiusa mentre era in coda (timeout, `close`) non parte.
  Future<void> _send({
    required String characterId,
    required PendingCompanion pending,
    required int token,
  }) async {
    if (_token != token) return;
    try {
      await (pending.operation == CompanionOperation.equip
          ? _repository.equip(characterId: characterId, petId: pending.petId)
          : _repository.unequip(characterId: characterId));
      _succeed(pending, token);
    } on PetEquipException catch (error) {
      _fail(pending, token, error.failure);
    } on Object {
      _fail(pending, token, PetEquipFailure.unknown);
    }
  }

  void _succeed(PendingCompanion pending, int token) {
    if (_token != token) return;
    final latest = _latest;
    if (latest != null && _matches(latest, pending)) {
      _settle();
      return;
    }
    _succeeded = true;
  }

  /// Una richiesta riuscita senza `characterUpdated` ha un esito incerto: la
  /// vista va riletta, senza banner.
  void _onSettleTimeout(PendingCompanion pending, int token) {
    if (_token != token) return;
    if (_succeeded) {
      _close(pending, CompanionOutcomeKind.settledByTimeout);
      return;
    }
    _fail(pending, token, PetEquipFailure.timedOut);
  }

  void _settle() {
    _forget();
    emit(CompanionState(outcome: state.outcome));
  }

  void _fail(PendingCompanion pending, int token, PetEquipFailure failure) {
    if (_token != token) return;
    _close(pending, CompanionOutcomeKind.failed, failure: failure);
  }

  void _close(
    PendingCompanion pending,
    CompanionOutcomeKind kind, {
    PetEquipFailure? failure,
  }) {
    _forget();
    emit(
      CompanionState(
        outcome: CompanionOutcome(
          sequence: ++_sequence,
          petId: pending.petId,
          operation: pending.operation,
          kind: kind,
          failure: failure,
        ),
      ),
    );
  }

  void _forget() {
    _token = null;
    _timer?.cancel();
    _timer = null;
    _succeeded = false;
  }

  static bool _matches(Character character, PendingCompanion pending) {
    final equippedId = character.assets?.pet?.id;
    return pending.operation == CompanionOperation.equip
        ? equippedId == pending.petId
        : equippedId == null;
  }
}
