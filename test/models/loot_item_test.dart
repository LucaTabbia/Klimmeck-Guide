import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/enums/injury_type.dart';
import 'package:klimmeck_guide/models/loot_item.dart';
import 'package:klimmeck_guide/models/loot_recovery.dart';

import '../helpers/fixtures/potion_fixtures.dart';

LootItem _potion({Object? injuries}) => LootItem.fromJson({
  'id': 'l-potion',
  'name': 'Pozione',
  'rarity': 'common',
  'effect': 'heal',
  'power': 12,
  if (injuries != null) 'canHeal': injuries,
});

void main() {
  group('LootItem.canHeal', () {
    test(
      'parses the injuries a heal item can cure as an unmodifiable list',
      () {
        final potion = _potion(injuries: ['deepCut', 'infection']);

        expect(potion.canHeal, [InjuryType.deepCut, InjuryType.infection]);
        expect(
          () => potion.canHeal.add(InjuryType.blackEye),
          throwsUnsupportedError,
        );
      },
    );

    test('drops unknown injury names instead of throwing', () {
      expect(_potion(injuries: ['deepCut', 'brokenWing']).canHeal, [
        InjuryType.deepCut,
      ]);
    });

    test('is empty when the wire omits the field or sends a non-list', () {
      expect(_potion().canHeal, isEmpty);
      expect(_potion(injuries: 'deepCut').canHeal, isEmpty);
      expect(_potion(injuries: 3).canHeal, isEmpty);
      expect(
        () => _potion().canHeal.add(InjuryType.blackEye),
        throwsUnsupportedError,
      );
    });

    test('writes the injury names back in toJson', () {
      expect(
        _potion(injuries: ['deepCut', 'infection']).toJson(),
        containsPair('canHeal', ['deepCut', 'infection']),
      );
      expect(_potion().toJson(), containsPair('canHeal', isEmpty));
    });

    test('round-trips through toJson and lists the injuries in props', () {
      final potion = _potion(injuries: ['deepCut', 'infection']);

      expect(LootItem.fromJson(potion.toJson()), potion);
      expect(_potion(injuries: ['deepCut']), isNot(potion));
      expect(_potion(), isNot(potion));
    });

    test('copyWith keeps the injuries unless they are replaced', () {
      final potion = _potion(injuries: ['deepCut', 'infection']);

      expect(potion.copyWith(power: 20).canHeal, [
        InjuryType.deepCut,
        InjuryType.infection,
      ]);
      expect(potion.copyWith(canHeal: [InjuryType.blackEye]).canHeal, [
        InjuryType.blackEye,
      ]);
    });
  });

  group('LootItem.recovery (BE Phase 18)', () {
    const halfHour = LootRecovery(time: 1800000, turns: 3);

    test('reads the recovery of a heal item (D-13)', () {
      expect(LootItem.fromJson(healPotionJson()).recovery, halfHour);
    });

    test(
      'an item without recovery or with a malformed one has recovery null (D-13)',
      () {
        final withNull = LootItem.fromJson(healPotionJson(recovery: null));
        final withZero = LootItem.fromJson(
          healPotionJson(recovery: {'time': 0, 'turns': 0}),
        );
        final withoutKey = LootItem.fromJson(
          healPotionJson()..remove('recovery'),
        );

        for (final item in [withNull, withZero, withoutKey]) {
          expect(item.recovery, isNull);
          expect(item.id, 'l-herb');
          expect(item.canHeal, [InjuryType.contusion]);
        }
      },
    );

    test('toJson writes the recovery and round trips (D-13)', () {
      final potion = LootItem.fromJson(healPotionJson());

      expect(
        potion.toJson(),
        containsPair('recovery', {'time': 1800000, 'turns': 3}),
      );
      expect(
        LootItem.fromJson(healPotionJson(recovery: null)).toJson(),
        containsPair('recovery', isNull),
      );
      expect(LootItem.fromJson(potion.toJson()), potion);
    });

    test('copyWith keeps and replaces the recovery (D-13)', () {
      final potion = LootItem.fromJson(healPotionJson());
      const hour = LootRecovery(time: 3600000, turns: 5);

      expect(potion.copyWith(power: 20).recovery, halfHour);
      expect(potion.copyWith(recovery: hour).recovery, hour);
    });

    test('props include recovery (D-13)', () {
      expect(
        LootItem.fromJson(healPotionJson()),
        isNot(LootItem.fromJson(healPotionJson(recovery: null))),
      );
      expect(
        LootItem.fromJson(healPotionJson()),
        isNot(
          LootItem.fromJson(
            healPotionJson(recovery: lootRecoveryJson(time: 3600000)),
          ),
        ),
      );
    });
  });
}
