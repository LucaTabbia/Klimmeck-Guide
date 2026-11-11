import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/enums/injury_type.dart';
import 'package:klimmeck_guide/models/enums/lore_type.dart';
import 'package:klimmeck_guide/models/use_item_result.dart';

import '../helpers/fixtures/lore_fixtures.dart';
import '../helpers/fixtures/potion_fixtures.dart';

void main() {
  group('UseItemResult', () {
    test('parses the outcome of a drunk potion (D-11)', () {
      final result = UseItemResult.fromJson(useItemResultJson());

      expect(result.hpBefore, 4);
      expect(result.hpAfter, 8);
      expect(result.injuriesHealed, [InjuryType.contusion]);
      expect(result.quantityLeft, 1);
      expect(result.loreUnlocked, isEmpty);
    });

    test('reads recoveryUntil as a UTC instant (D-11)', () {
      final result = UseItemResult.fromJson(useItemResultJson());

      expect(result.recoveryUntil, DateTime.utc(2026, 10, 27, 10, 30));
      expect(result.recoveryUntil.isUtc, isTrue);
    });

    test(
      'drops unknown healed injuries and lore entries without id or name (D-11)',
      () {
        final result = UseItemResult.fromJson(
          useItemResultJson(
            injuriesHealed: ['contusion', 'dragonBite'],
            loreUnlocked: [
              loreRefJson(
                id: 'lore-limit',
                name: 'Il limite del corpo',
                type: 'knowledge',
              ),
              {'name': 'x'},
            ],
          ),
        );

        expect(result.injuriesHealed, [InjuryType.contusion]);
        expect(result.loreUnlocked, hasLength(1));
        expect(result.loreUnlocked.single.id, 'lore-limit');
        expect(result.loreUnlocked.single.type, LoreType.knowledge);
      },
    );

    test('a result without hp, quantity or recoveryUntil throws (D-11)', () {
      for (final key in [
        'hpBefore',
        'hpAfter',
        'quantityLeft',
        'recoveryUntil',
      ]) {
        expect(
          () => UseItemResult.fromJson(useItemResultJson()..remove(key)),
          throwsA(anything),
          reason: key,
        );
      }
      expect(
        () => UseItemResult.fromJson(useItemResultJson(recoveryUntil: 'soon')),
        throwsA(anything),
      );
    });

    test('toJson round trips (D-11)', () {
      final result = UseItemResult.fromJson(
        useItemResultJson(
          loreUnlocked: [
            loreRefJson(
              id: 'lore-limit',
              name: 'Il limite del corpo',
              type: 'knowledge',
            ),
          ],
        ),
      );

      expect(result.toJson(), {
        'hpBefore': 4,
        'hpAfter': 8,
        'injuriesHealed': ['contusion'],
        'quantityLeft': 1,
        'recoveryUntil': '2026-10-27T10:30:00.000Z',
        'loreUnlocked': [
          {
            'id': 'lore-limit',
            'name': 'Il limite del corpo',
            'type': 'knowledge',
          },
        ],
      });
      expect(UseItemResult.fromJson(result.toJson()), result);
    });

    test('props compare every field (D-11)', () {
      final result = UseItemResult.fromJson(useItemResultJson());

      expect(UseItemResult.fromJson(useItemResultJson()), result);
      final variants = [
        useItemResultJson(hpBefore: 5),
        useItemResultJson(hpAfter: 9),
        useItemResultJson(injuriesHealed: const []),
        useItemResultJson(quantityLeft: 0),
        useItemResultJson(recoveryUntil: '2026-10-27T11:00:00.000Z'),
        useItemResultJson(loreUnlocked: [loreRefJson()]),
      ];
      for (final variant in variants) {
        expect(UseItemResult.fromJson(variant), isNot(result));
      }
    });
  });
}
