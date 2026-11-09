/// Tipo di un `QuestResult` (BE Phase 15 D-14): l'esito di una quest o il
/// report di un'imboscata in viaggio.
enum QuestResultKind {
  quest,
  ambush;

  /// Mancante o sconosciuto vale `quest`: un BE più vecchio non manda il
  /// campo (regola tollerante della Phase 13, 16-CONTEXT D-01).
  static QuestResultKind fromWire(Object? value) =>
      (value is String ? values.asNameMap()[value] : null) ?? quest;
}
