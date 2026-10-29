/// Esito di una quest risolta (`QuestOutcome` del BE Phase 9).
enum QuestOutcome {
  success('Vittoria'),
  failure('Sconfitta'),
  rescued('Sei stato salvato'),
  death('È morto'),
  gmCompleted('Missione completata');

  const QuestOutcome(this.label);

  /// Intestazione del foglio esiti (D-04), copy provvisoria (D-19).
  final String label;

  /// `null` per valori sconosciuti o non stringa: il chiamante scarta il risultato.
  static QuestOutcome? fromWire(Object? value) =>
      value is String ? values.asNameMap()[value] : null;
}
