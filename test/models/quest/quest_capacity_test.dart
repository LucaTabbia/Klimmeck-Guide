import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/enums/title_type.dart';
import 'package:klimmeck_guide/models/quest/adventurer_slot.dart';
import 'package:klimmeck_guide/models/quest/quest_capacity.dart';
import 'package:klimmeck_guide/models/quest/registered_adventurer.dart';

RegisteredAdventurer reg(TitleType? title, [int n = 0]) =>
    RegisteredAdventurer(characterId: 'c-$n', title: title);

List<RegisteredAdventurer> regs(List<TitleType?> titles) => [
  for (var i = 0; i < titles.length; i++) reg(titles[i], i),
];

void main() {
  group('isFullForEveryone', () {
    test('is false with no slots', () {
      expect(isFullForEveryone(const [], const []), isFalse);
    });

    test('is true when registrations reach the total', () {
      const slots = [AdventurerSlot(title: null, count: 2)];
      expect(isFullForEveryone(slots, regs([null, null])), isTrue);
      expect(isFullForEveryone(slots, regs([null])), isFalse);
    });
  });

  group('rank capacity (BE Phase 8 D-32)', () {
    const canonical = [
      AdventurerSlot(title: TitleType.hero, count: 1),
      AdventurerSlot(title: null, count: 2),
    ];

    test('D-32 canonical: a third paladin is full, a hero is not', () {
      final registered = regs([TitleType.paladin, TitleType.mage]);
      expect(
        canRegisterWithTitle(canonical, registered, TitleType.paladin),
        isFalse,
      );
      expect(
        canRegisterWithTitle(canonical, registered, TitleType.hero),
        isTrue,
      );
      expect(isFullFor(canonical, registered, TitleType.paladin), isTrue);
      expect(isFullFor(canonical, registered, TitleType.hero), isFalse);
    });

    test('exact slots full for paladins but not for heroes', () {
      const slots = [
        AdventurerSlot(title: TitleType.hero, count: 5),
        AdventurerSlot(title: TitleType.paladin, count: 4),
      ];
      final registered = regs(List.filled(4, TitleType.paladin));
      expect(isFullFor(slots, registered, TitleType.paladin), isTrue);
      expect(isFullFor(slots, registered, TitleType.hero), isFalse);
    });

    test('full for everyone when the total is reached', () {
      const slots = [
        AdventurerSlot(title: TitleType.hero, count: 5),
        AdventurerSlot(title: TitleType.paladin, count: 4),
      ];
      final registered = regs([
        ...List.filled(5, TitleType.hero),
        ...List.filled(4, TitleType.paladin),
      ]);
      expect(isFullFor(slots, registered, TitleType.hero), isTrue);
      expect(isFullFor(slots, registered, TitleType.mage), isTrue);
    });

    test('legacy count-only shapes fall back to the total', () {
      final slots = AdventurerSlot.listFrom(1);
      final registered = RegisteredAdventurer.listFrom(['c-9']);
      expect(isFullFor(slots, registered, TitleType.rookie), isTrue);
      expect(
        isFullFor(
          AdventurerSlot.listFrom(2),
          RegisteredAdventurer.listFrom(['c-9']),
          TitleType.rookie,
        ),
        isFalse,
      );
    });

    test('a null title is the total rule; no slots is never full', () {
      final registered = regs([TitleType.paladin, TitleType.mage]);
      expect(
        isFullFor(canonical, registered, null),
        isFullForEveryone(canonical, registered),
      );
      expect(isFullFor(const [], registered, TitleType.hero), isFalse);
    });
  });
}
