import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/character/character_infos.dart';

void main() {
  test('reads the background as the list of its entries, in order', () {
    final infos = CharacterInfos.fromJson({
      'name': 'Aria',
      'background': ['Nata a Drustea.', 'Ha salvato Bosa.'],
    });

    expect(infos.background, ['Nata a Drustea.', 'Ha salvato Bosa.']);
    expect(infos.toJson()['background'], [
      'Nata a Drustea.',
      'Ha salvato Bosa.',
    ]);
  });

  test('a missing or malformed background has no entries', () {
    expect(CharacterInfos.fromJson({'name': 'Aria'}).background, isEmpty);
    expect(
      CharacterInfos.fromJson({'name': 'Aria', 'background': null}).background,
      isEmpty,
    );
    expect(
      CharacterInfos.fromJson({
        'name': 'Aria',
        'background': ['Nata a Drustea.', 7, null],
      }).background,
      ['Nata a Drustea.'],
    );
  });

  test('two characters differ by their background entries', () {
    CharacterInfos infosWith(List<String> background) =>
        CharacterInfos.fromJson({'name': 'Aria', 'background': background});

    expect(infosWith(['a']), infosWith(['a']));
    expect(infosWith(['a']), isNot(infosWith(['a', 'b'])));
  });
}
