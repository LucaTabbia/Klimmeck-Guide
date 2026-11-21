/// Le 26 lettere dei segnalibri della Libreria, in ordine.
const List<String> alphabet = [
  'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', //
  'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z',
];

const Map<String, String> _plainLetterOf = {
  'à': 'a', 'á': 'a', 'â': 'a', 'ä': 'a', 'ã': 'a', 'å': 'a', //
  'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e', //
  'ì': 'i', 'í': 'i', 'î': 'i', 'ï': 'i', //
  'ò': 'o', 'ó': 'o', 'ô': 'o', 'ö': 'o', 'õ': 'o', 'ø': 'o', //
  'ù': 'u', 'ú': 'u', 'û': 'u', 'ü': 'u', //
  'ç': 'c', 'ñ': 'n', 'ý': 'y',
};

/// Lettera iniziale di [text] fra le 26 di [alphabet], senza accenti e in
/// minuscolo; `null` se il testo non si apre con una lettera.
String? initialLetterOf(String? text) {
  final trimmed = text?.trimLeft() ?? '';
  if (trimmed.isEmpty) return null;
  final first = String.fromCharCode(trimmed.runes.first).toLowerCase();
  final plain = _plainLetterOf[first] ?? first;
  return alphabet.contains(plain) ? plain : null;
}
