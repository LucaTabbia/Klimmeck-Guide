/// Regole di forma del nome del personaggio e del compagno (D-31): solo UX, il
/// backend resta l'autorità.
library;

enum NameError { required, tooShort, tooLong, invalidCharacters }

const int nameMinLength = 2;
const int nameMaxLength = 20;

final RegExp _nameCharset = RegExp(r"^[\p{L}'’\- ]+$", unicode: true);
final RegExp _letter = RegExp(r'\p{L}', unicode: true);
final RegExp _whitespaceRun = RegExp(r'\s+');

String normalizedNameOf(String raw) =>
    raw.trim().replaceAll(_whitespaceRun, ' ');

NameError? nameErrorOf(String raw) {
  final normalized = normalizedNameOf(raw);
  if (normalized.isEmpty) return NameError.required;
  if (normalized.length < nameMinLength) return NameError.tooShort;
  if (normalized.length > nameMaxLength) return NameError.tooLong;
  if (!_nameCharset.hasMatch(normalized) || !_letter.hasMatch(normalized)) {
    return NameError.invalidCharacters;
  }
  return null;
}

extension NameErrorMessage on NameError {
  /// Null quando il campo è solo vuoto: "Crea" resta disabilitato senza rimproveri.
  String? get message => switch (this) {
    NameError.required => null,
    NameError.tooShort => 'Il nome deve avere almeno 2 lettere',
    NameError.tooLong => 'Il nome può avere al massimo 20 caratteri',
    NameError.invalidCharacters => 'Solo lettere, spazi, apostrofi e trattini',
  };
}
