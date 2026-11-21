import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/utils/initial_letter.dart';

void main() {
  test('reads the first letter in lower case', () {
    expect(initialLetterOf('Andogan'), 'a');
    expect(initialLetterOf('bosa'), 'b');
  });

  test('skips the leading spaces', () {
    expect(initialLetterOf('  Valtorre'), 'v');
  });

  test('reads an accented initial as its plain letter', () {
    expect(initialLetterOf('Èrebo'), 'e');
    expect(initialLetterOf('àncora'), 'a');
    expect(initialLetterOf('Ørn'), 'o');
    expect(initialLetterOf('Ñandu'), 'n');
  });

  test('a text that does not open with a letter has no initial', () {
    expect(initialLetterOf(null), isNull);
    expect(initialLetterOf(''), isNull);
    expect(initialLetterOf('   '), isNull);
    expect(initialLetterOf('7 Sorelle'), isNull);
    expect(initialLetterOf('«Il Corvo»'), isNull);
  });

  test('the alphabet holds the 26 letters in order', () {
    expect(alphabet, hasLength(26));
    expect(alphabet.first, 'a');
    expect(alphabet.last, 'z');
    expect([...alphabet]..sort(), alphabet);
  });
}
