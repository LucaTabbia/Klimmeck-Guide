/// Origine di una magia (D-01): macro-classe sopra uso ed energia. `void` è
/// una parola riservata in Dart: il valore attraversa il filo solo col suo
/// nome esplicito.
enum SpellOrigin {
  theVoid(wireName: 'void', label: 'Vuoto'),
  arcane(wireName: 'arcane', label: 'Arcana'),
  shamanic(wireName: 'shamanic', label: 'Sciamanica');

  const SpellOrigin({required this.wireName, required this.label});

  final String wireName;
  final String label;

  static SpellOrigin? fromWire(Object? value) {
    for (final origin in values) {
      if (origin.wireName == value) return origin;
    }
    return null;
  }
}
