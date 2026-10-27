part of 'spells_cubit.dart';

enum SpellOutcomeKind {
  blockedSlotsFull,
  blockedNoSlots,
  failed,

  /// Chiusa dal timeout dopo una risposta riuscita senza `characterUpdated`:
  /// esito incerto, nessun banner né rimbalzo, solo rilettura (D-17).
  settledByTimeout,
}

/// Esito da mostrare una volta (banner, riallineamento, rimbalzo): la
/// `sequence` crescente rende distinti due esiti identici consecutivi (D-17, D-18).
class SpellOutcome extends Equatable {
  const SpellOutcome({
    required this.sequence,
    required this.spellId,
    required this.operation,
    required this.kind,
    this.failure,
  });

  final int sequence;
  final String spellId;
  final SpellOperation operation;
  final SpellOutcomeKind kind;
  final SpellEquipFailure? failure;

  /// La carta torna al suo posto solo per un blocco o un rifiuto (D-18).
  bool get springsBack => kind != SpellOutcomeKind.settledByTimeout;

  @override
  List<Object?> get props => [sequence, spellId, operation, kind, failure];
}

/// Overlay ottimistico sopra lo stato di `CharacterCubit` (D-16): mai stato
/// del personaggio.
class SpellsState extends Equatable {
  const SpellsState({this.pending = const {}, this.outcome});

  final Map<String, SpellOperation> pending;
  final SpellOutcome? outcome;

  SpellsState copyWith({
    Map<String, SpellOperation>? pending,
    SpellOutcome? outcome,
  }) => SpellsState(
    pending: pending ?? this.pending,
    outcome: outcome ?? this.outcome,
  );

  @override
  List<Object?> get props => [pending, outcome];
}
