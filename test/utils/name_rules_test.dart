import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/utils/name_rules.dart';

void main() {
  test('normalises whitespace like the character name (D-31)', () {
    expect(normalizedNameOf('  Fe   nrir '), 'Fe nrir');
  });

  test(
    '2..20 characters of letters, spaces, apostrophes and hyphens (D-31)',
    () {
      expect(nameErrorOf(''), NameError.required);
      expect(nameErrorOf('A'), NameError.tooShort);
      expect(nameErrorOf('A' * 21), NameError.tooLong);
      expect(nameErrorOf('R2D2'), NameError.invalidCharacters);
      expect(nameErrorOf("'-"), NameError.invalidCharacters);
      expect(nameErrorOf('Ombra d’Argento'), isNull);
      expect(nameMinLength, 2);
      expect(nameMaxLength, 20);
    },
  );

  test('the messages are the character creation ones (D-31)', () {
    expect(NameError.tooShort.message, 'Il nome deve avere almeno 2 lettere');
    expect(
      NameError.tooLong.message,
      'Il nome può avere al massimo 20 caratteri',
    );
    expect(
      NameError.invalidCharacters.message,
      'Solo lettere, spazi, apostrofi e trattini',
    );
    expect(NameError.required.message, isNull);
  });
}
