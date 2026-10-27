import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/spell/spell_state.dart';

import '../../helpers/fixtures/spell_fixtures.dart';

void main() {
  group('fromJson', () {
    test('parses spell id, usages and UTC recoveries', () {
      final state = SpellState.fromJson(spellStateJson());

      expect(state.spellId, 'spell-1');
      expect(state.usages, 1);
      expect(state.recoveries, [
        DateTime.utc(2026, 10, 27, 10, 12),
        DateTime.utc(2026, 10, 27, 10, 42),
      ]);
      expect(state.recoveries.every((instant) => instant.isUtc), isTrue);
    });

    test('sorts the recoveries ascending', () {
      final state = SpellState.fromJson(
        spellStateJson(
          recoveries: const [
            '2026-10-27T10:42:00.000Z',
            '2026-10-27T10:12:00.000Z',
          ],
        ),
      );

      expect(state.recoveries, [
        DateTime.utc(2026, 10, 27, 10, 12),
        DateTime.utc(2026, 10, 27, 10, 42),
      ]);
    });

    test('recoveries are unmodifiable', () {
      final state = SpellState.fromJson(spellStateJson());

      expect(
        () => state.recoveries.add(DateTime.utc(2026)),
        throwsUnsupportedError,
      );
    });
  });

  group('toJson', () {
    test('round trips', () {
      final state = SpellState.fromJson(spellStateJson());

      expect(SpellState.fromJson(state.toJson()), state);
    });

    test('writes the spell as an id object and UTC instants', () {
      final json = SpellState.fromJson(spellStateJson()).toJson();

      expect(json['spell'], {'id': 'spell-1'});
      expect(
        (json['recoveries'] as List).every(
          (value) => (value as String).endsWith('Z'),
        ),
        isTrue,
      );
    });
  });

  group('tryFromJson', () {
    final malformed = <String, Object?>{
      'null': null,
      'a string': 'spell-state',
      'a map without spell': spellStateJson()..remove('spell'),
      'a spell without id': spellStateJson()..['spell'] = <String, dynamic>{},
      'non-numeric usages': spellStateJson()..['usages'] = 'x',
      'non-list recoveries': spellStateJson()..['recoveries'] = 'x',
      'a non-string recovery': spellStateJson(recoveries: const [42]),
      'an unparsable recovery': spellStateJson(
        recoveries: const ['not-a-date'],
      ),
    };

    for (final entry in malformed.entries) {
      test('returns null for ${entry.key}', () {
        expect(SpellState.tryFromJson(entry.value), isNull);
      });
    }

    test('parses a valid entry', () {
      expect(
        SpellState.tryFromJson(spellStateJson()),
        SpellState.fromJson(spellStateJson()),
      );
    });
  });

  group('equality', () {
    test('equal values are equal', () {
      expect(
        SpellState.fromJson(spellStateJson()),
        SpellState.fromJson(spellStateJson()),
      );
    });

    test('different recoveries are different', () {
      expect(
        SpellState.fromJson(spellStateJson()) ==
            SpellState.fromJson(
              spellStateJson(recoveries: const ['2026-10-27T10:12:00.000Z']),
            ),
        isFalse,
      );
    });
  });
}
