import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/spell/spell_recovery_status.dart';

import '../../helpers/fixtures/spell_fixtures.dart';

SpellRecoveryInput _input({
  int usages = 1,
  int? maxUsages = 3,
  List<DateTime> recoveries = const [],
}) => SpellRecoveryInput(
  spellId: 'spell-1',
  usages: usages,
  maxUsages: maxUsages,
  recoveries: recoveries,
);

DateTime _at(int minute, [int second = 0, int millisecond = 0]) =>
    DateTime.utc(2026, 10, 27, 10, minute, second, millisecond);

void main() {
  final now = spellFixtureNow;

  group('spellRecoveryStatusOf full', () {
    test('usages at the maximum without recoveries is full', () {
      expect(
        spellRecoveryStatusOf(_input(usages: 3), now),
        const SpellRecoveryFull(),
      );
    });

    test('usages at the maximum win over leftover recoveries', () {
      expect(
        spellRecoveryStatusOf(_input(usages: 3, recoveries: [_at(12)]), now),
        const SpellRecoveryFull(),
      );
    });

    test('usages above the maximum is full', () {
      expect(
        spellRecoveryStatusOf(_input(usages: 5), now),
        const SpellRecoveryFull(),
      );
    });

    test('an unknown maximum is full', () {
      expect(
        spellRecoveryStatusOf(
          _input(maxUsages: null, recoveries: [_at(12)]),
          now,
        ),
        const SpellRecoveryFull(),
      );
    });
  });

  group('spellRecoveryStatusOf countdown', () {
    test('rounds the remaining time up to whole minutes', () {
      expect(
        spellRecoveryStatusOf(_input(recoveries: [_at(11, 30), _at(42)]), now),
        const SpellRecoveryCountdown(remainingMinutes: 12),
      );
    });

    test('exactly one minute left reads one minute', () {
      expect(
        spellRecoveryStatusOf(_input(recoveries: [_at(1)]), now),
        const SpellRecoveryCountdown(remainingMinutes: 1),
      );
    });

    test('59 seconds left is under a minute', () {
      expect(
        spellRecoveryStatusOf(_input(recoveries: [_at(0, 59)]), now),
        const SpellRecoveryCountdown(remainingMinutes: 0),
      );
    });

    test('1 millisecond left is under a minute', () {
      expect(
        spellRecoveryStatusOf(_input(recoveries: [_at(0, 0, 1)]), now),
        const SpellRecoveryCountdown(remainingMinutes: 0),
      );
    });

    test('uses the earliest instant of an unsorted list', () {
      expect(
        spellRecoveryStatusOf(_input(recoveries: [_at(42), _at(12)]), now),
        const SpellRecoveryCountdown(remainingMinutes: 12),
      );
    });

    test('two instants within the same ceil minute are equal states', () {
      final input = _input(recoveries: [_at(12)]);

      expect(
        spellRecoveryStatusOf(input, now),
        spellRecoveryStatusOf(input, now.add(const Duration(seconds: 10))),
      );
    });
  });

  group('spellRecoveryStatusOf arriving', () {
    test('an instant equal to now is arriving', () {
      expect(
        spellRecoveryStatusOf(_input(recoveries: [_at(0)]), now),
        const SpellRecoveryArriving(),
      );
    });

    test('a past instant is arriving', () {
      expect(
        spellRecoveryStatusOf(
          _input(recoveries: [DateTime.utc(2026, 10, 27, 9, 59)]),
          now,
        ),
        const SpellRecoveryArriving(),
      );
    });
  });

  group('spellRecoveryStatusOf unknown', () {
    test('below the maximum without instants is unknown', () {
      expect(
        spellRecoveryStatusOf(_input(), now),
        const SpellRecoveryUnknown(),
      );
    });
  });

  group('equality', () {
    test('countdowns with the same minutes are equal', () {
      expect(
        const SpellRecoveryCountdown(remainingMinutes: 12),
        const SpellRecoveryCountdown(remainingMinutes: 12),
      );
      expect(
        const SpellRecoveryCountdown(remainingMinutes: 12),
        isNot(const SpellRecoveryCountdown(remainingMinutes: 11)),
      );
    });

    test('SpellRecoveryInput compares id, usages, maximum and instants', () {
      expect(_input(recoveries: [_at(12)]), _input(recoveries: [_at(12)]));
      expect(_input().props, ['spell-1', 1, 3, const <DateTime>[]]);
      expect(_input(usages: 2), isNot(_input()));
      expect(_input(maxUsages: 4), isNot(_input()));
      expect(_input(recoveries: [_at(12)]), isNot(_input()));
      expect(
        const SpellRecoveryInput(
          spellId: 'spell-2',
          usages: 1,
          maxUsages: 3,
          recoveries: [],
        ),
        isNot(_input()),
      );
    });
  });
}
