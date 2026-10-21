import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/enums/title_type.dart';
import 'package:klimmeck_guide/models/quest/registered_adventurer.dart';

void main() {
  group('RegisteredAdventurer.listFrom', () {
    test('parses the Phase 8 {character, title} shape', () {
      expect(
        RegisteredAdventurer.listFrom([
          {'character': 'c-1', 'title': 'paladin'},
        ]),
        const [
          RegisteredAdventurer(characterId: 'c-1', title: TitleType.paladin),
        ],
      );
    });

    test('parses the Phase 7 id strings with an unknown rank', () {
      expect(RegisteredAdventurer.listFrom(['c-1', 'c-2']), const [
        RegisteredAdventurer(characterId: 'c-1', title: null),
        RegisteredAdventurer(characterId: 'c-2', title: null),
      ]);
    });

    test('yields an empty list for null', () {
      expect(RegisteredAdventurer.listFrom(null), isEmpty);
    });

    test('drops malformed elements', () {
      expect(
        RegisteredAdventurer.listFrom([
          42,
          {'title': 'hero'},
          {'character': 'c-3', 'title': 'hero'},
        ]),
        const [RegisteredAdventurer(characterId: 'c-3', title: TitleType.hero)],
      );
    });

    test('an unknown title string becomes an unknown rank', () {
      expect(
        RegisteredAdventurer.listFrom([
          {'character': 'c-1', 'title': 'wizard'},
        ]),
        const [RegisteredAdventurer(characterId: 'c-1', title: null)],
      );
    });
  });

  test('toJson emits character and title', () {
    expect(
      const RegisteredAdventurer(
        characterId: 'c-1',
        title: TitleType.mage,
      ).toJson(),
      {'character': 'c-1', 'title': 'mage'},
    );
  });
}
