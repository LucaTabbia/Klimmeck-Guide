import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/spell.dart';
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

    test('normalises an offset-bearing instant to the same UTC instant', () {
      final state = SpellState.fromJson(
        spellStateJson(recoveries: const ['2026-10-27T12:12:00.000+02:00']),
      );

      expect(state.recoveries.single, DateTime.utc(2026, 10, 27, 10, 12));
      expect(state.recoveries.single.isUtc, isTrue);
    });

    test('normalises an instant without zone to UTC', () {
      const raw = '2026-10-27T10:12:00.000';
      final state = SpellState.fromJson(
        spellStateJson(recoveries: const [raw]),
      );

      expect(state.recoveries.single, DateTime.parse(raw).toUtc());
      expect(state.recoveries.single.isUtc, isTrue);
    });

    test('recoveries are unmodifiable', () {
      final state = SpellState.fromJson(spellStateJson());

      expect(
        () => state.recoveries.add(DateTime.utc(2026)),
        throwsUnsupportedError,
      );
    });

    test('parses the full spell of the entry (D-05)', () {
      final state = SpellState.fromJson(
        spellStateJson(
          spellId: 's-2',
          spell: spellJson(id: 's-2', name: 'Scudo'),
        ),
      );

      expect(state.spell.name, 'Scudo');
      expect(state.spell, Spell.fromJson(spellJson(id: 's-2', name: 'Scudo')));
      expect(state.spellId, 's-2');
    });

    test('parses active from the entry (D-05)', () {
      expect(SpellState.fromJson(spellStateJson(active: true)).active, isTrue);
      expect(SpellState.fromJson(spellStateJson()).active, isFalse);
    });

    test('an absent or malformed active is false (D-05)', () {
      final absent = spellStateJson(active: true)..remove('active');
      expect(SpellState.fromJson(absent).active, isFalse);

      for (final Object? malformed in ['yes', 1, null]) {
        final json = spellStateJson(active: true)..['active'] = malformed;

        expect(
          SpellState.fromJson(json).active,
          isFalse,
          reason: 'active: $malformed',
        );
      }
    });

    test('an entry whose spell carries only an id still parses (D-05)', () {
      final state = SpellState.tryFromJson(<String, dynamic>{
        'spell': <String, dynamic>{'id': 's-1'},
        'usages': 1,
        'recoveries': <Object?>[],
      });

      expect(state, isNotNull);
      expect(state!.spell.id, 's-1');
      expect(state.spell.name, isNull);
      expect(state.usages, 1);
      expect(state.active, isFalse);
    });

    test('an entry whose spell has no id is null (D-05)', () {
      final json = spellStateJson()..['spell'] = (spellJson()..remove('id'));

      expect(SpellState.tryFromJson(json), isNull);
    });
  });

  group('toJson', () {
    test('round trips', () {
      final state = SpellState.fromJson(spellStateJson());

      expect(SpellState.fromJson(state.toJson()), state);
    });

    test('toJson writes the full spell and active (D-05)', () {
      final state = SpellState.fromJson(spellStateJson(active: true));
      final json = state.toJson();

      expect(json['spell'], state.spell.toJson());
      expect(json['spell'], Spell.fromJson(spellJson()).toJson());
      expect(json['active'], isTrue);
      expect(SpellState.fromJson(spellStateJson()).toJson()['active'], isFalse);
    });

    test('writes UTC instants', () {
      final json = SpellState.fromJson(spellStateJson()).toJson();

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

    test('active and the spell are part of the props (D-05)', () {
      expect(
        SpellState.fromJson(spellStateJson()) ==
            SpellState.fromJson(spellStateJson(active: true)),
        isFalse,
      );
      expect(
        SpellState.fromJson(spellStateJson()) ==
            SpellState.fromJson(
              spellStateJson(spell: spellJson(name: 'Scudo')),
            ),
        isFalse,
      );
    });
  });
}
