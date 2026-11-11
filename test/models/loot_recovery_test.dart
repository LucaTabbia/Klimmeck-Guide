import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/loot_recovery.dart';

import '../helpers/fixtures/potion_fixtures.dart';

void main() {
  group('LootRecovery', () {
    test('parses time and turns (D-13)', () {
      final recovery = LootRecovery.tryFromJson(lootRecoveryJson())!;

      expect(recovery.time, 1800000);
      expect(recovery.turns, 3);
    });

    test('duration is the time in milliseconds (D-13)', () {
      expect(
        LootRecovery.tryFromJson(lootRecoveryJson())!.duration,
        const Duration(milliseconds: 1800000),
      );
    });

    test('a malformed recovery is null (D-13)', () {
      expect(LootRecovery.tryFromJson(null), isNull);
      expect(LootRecovery.tryFromJson('30 min'), isNull);
      expect(LootRecovery.tryFromJson([]), isNull);
      expect(LootRecovery.tryFromJson({'turns': 3}), isNull);
      expect(
        LootRecovery.tryFromJson(lootRecoveryJson(time: '1800000')),
        isNull,
      );
      expect(LootRecovery.tryFromJson(lootRecoveryJson(time: 0)), isNull);
      expect(LootRecovery.tryFromJson(lootRecoveryJson(time: -1)), isNull);
      expect(LootRecovery.tryFromJson(lootRecoveryJson(time: 1.5)), isNull);
    });

    test(
      'a missing or malformed turns is read as 0 and the recovery is kept (D-21)',
      () {
        const expected = LootRecovery(time: 1800000, turns: 0);

        expect(LootRecovery.tryFromJson({'time': 1800000}), expected);
        expect(
          LootRecovery.tryFromJson(lootRecoveryJson(turns: null)),
          expected,
        );
        expect(LootRecovery.tryFromJson(lootRecoveryJson(turns: -1)), expected);
        expect(
          LootRecovery.tryFromJson(lootRecoveryJson(turns: '3')),
          expected,
        );
        expect(
          LootRecovery.tryFromJson(lootRecoveryJson(turns: 1.5)),
          expected,
        );
      },
    );

    test('toJson round trips (D-13)', () {
      final recovery = LootRecovery.tryFromJson(lootRecoveryJson())!;

      expect(recovery.toJson(), {'time': 1800000, 'turns': 3});
      expect(LootRecovery.tryFromJson(recovery.toJson()), recovery);
    });

    test('props compare time and turns (D-13)', () {
      const recovery = LootRecovery(time: 1800000, turns: 3);

      expect(recovery, const LootRecovery(time: 1800000, turns: 3));
      expect(recovery, isNot(const LootRecovery(time: 3600000, turns: 3)));
      expect(recovery, isNot(const LootRecovery(time: 1800000, turns: 1)));
    });
  });
}
