/// Tipo del turno di una dungeon (BE Phase 21, D-12): dove il cammino si è
/// fermato. Un valore sconosciuto vale `null`, mai un'eccezione.
enum DungeonTurnKind {
  exploration,
  fight;

  static DungeonTurnKind? fromWire(Object? value) =>
      value is String ? values.asNameMap()[value] : null;
}
