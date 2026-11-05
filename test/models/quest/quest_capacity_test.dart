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

  group('legend on hero seats (BE 13.1 D-08)', () {
    const heroSeat = [AdventurerSlot(title: TitleType.hero, count: 1)];

    test('lets a legend take a hero seat', () {
      expect(
        canRegisterWithTitle(heroSeat, const [], TitleType.legend),
        isTrue,
      );
      expect(
        canRegisterWithTitle(
          const [AdventurerSlot(title: TitleType.hero, count: 2)],
          regs([TitleType.legend]),
          TitleType.hero,
        ),
        isTrue,
      );
      expect(
        canRegisterWithTitle(
          heroSeat,
          regs([TitleType.legend]),
          TitleType.hero,
        ),
        isFalse,
      );
      expect(
        canRegisterWithTitle(
          heroSeat,
          regs([TitleType.hero]),
          TitleType.legend,
        ),
        isFalse,
      );
      expect(
        isFullFor(heroSeat, regs([TitleType.legend]), TitleType.legend),
        isTrue,
      );
    });

    test('fills the legend seats before the hero seats', () {
      const slots = [
        AdventurerSlot(title: TitleType.legend, count: 1),
        AdventurerSlot(title: TitleType.hero, count: 1),
      ];
      final oneLegend = regs([TitleType.legend]);
      final twoLegends = regs([TitleType.legend, TitleType.legend]);
      expect(canRegisterWithTitle(slots, oneLegend, TitleType.legend), isTrue);
      expect(canRegisterWithTitle(slots, oneLegend, TitleType.hero), isTrue);
      expect(canRegisterWithTitle(slots, twoLegends, TitleType.hero), isFalse);
      expect(
        canRegisterWithTitle(slots, twoLegends, TitleType.legend),
        isFalse,
      );
    });

    test('counts a legend on a hero seat before the wildcards', () {
      const slots = [
        AdventurerSlot(title: TitleType.hero, count: 1),
        AdventurerSlot(title: null, count: 1),
      ];
      expect(
        canRegisterWithTitle(
          slots,
          regs([TitleType.legend]),
          TitleType.paladin,
        ),
        isTrue,
      );
      expect(
        canRegisterWithTitle(
          slots,
          regs([TitleType.legend, TitleType.legend]),
          TitleType.paladin,
        ),
        isFalse,
      );
    });

    test('scales no other title', () {
      final admitted = <String>[];
      for (final title in TitleType.values) {
        for (final rank in TitleType.values) {
          if (rank == title) continue;
          if (title == TitleType.legend && rank == TitleType.hero) continue;
          final seat = [AdventurerSlot(title: rank, count: 1)];
          if (canRegisterWithTitle(seat, const [], title)) {
            admitted.add('${title.name} on ${rank.name}');
          }
        }
      }
      expect(admitted, isEmpty);
    });
  });
}
