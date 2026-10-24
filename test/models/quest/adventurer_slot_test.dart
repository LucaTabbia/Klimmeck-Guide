import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/enums/title_type.dart';
import 'package:klimmeck_guide/models/quest/adventurer_slot.dart';

void main() {
  group('AdventurerSlot.listFrom', () {
    test('parses the Phase 8 slot list', () {
      expect(
        AdventurerSlot.listFrom([
          {'title': 'hero', 'count': 5},
          {'title': null, 'count': 2},
        ]),
        const [
          AdventurerSlot(title: TitleType.hero, count: 5),
          AdventurerSlot(title: null, count: 2),
        ],
      );
    });

    test('maps the Phase 7 Int to a single any-rank slot', () {
      expect(AdventurerSlot.listFrom(3), const [
        AdventurerSlot(title: null, count: 3),
      ]);
    });

    test('yields no slots for 0, null and unexpected shapes', () {
      expect(AdventurerSlot.listFrom(0), isEmpty);
      expect(AdventurerSlot.listFrom(null), isEmpty);
      expect(AdventurerSlot.listFrom('x'), isEmpty);
    });

    test('throws on an unknown title (handled by Quest.tryFromJson)', () {
      expect(
        () => AdventurerSlot.listFrom([
          {'title': 'wizard', 'count': 1},
        ]),
        throwsA(anything),
      );
    });
  });

  group('AdventurerSlot', () {
    test('toJson/fromJson round trip', () {
      const slot = AdventurerSlot(title: TitleType.mage, count: 2);
      expect(AdventurerSlot.fromJson(slot.toJson()), slot);
      expect(slot.toJson(), {'title': 'mage', 'count': 2});
    });

    test('Equatable on title and count', () {
      expect(
        const AdventurerSlot(title: null, count: 1),
        const AdventurerSlot(title: null, count: 1),
      );
      expect(
        const AdventurerSlot(title: null, count: 1) ==
            const AdventurerSlot(title: TitleType.hero, count: 1),
        isFalse,
      );
    });
  });
}
