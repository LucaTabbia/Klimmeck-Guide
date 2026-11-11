import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/character/character_status.dart';
import 'package:klimmeck_guide/models/character/legacy_spell_states.dart';

/// Magia di catalogo com'è servita oggi nella lista delle conosciute.
Map<String, dynamic> _known(String id, {String? name, Object? maxUsages = 3}) =>
    {'id': id, 'name': name ?? 'Magia $id', 'maxUsages': maxUsages};

/// Stato per id com'è servito oggi (solo l'id della magia).
Map<String, dynamic> _state(
  String id, {
  Object? usages = 1,
  Object? recoveries = const ['2026-10-27T10:12:00.000Z'],
}) => {
  'spell': {'id': id},
  'usages': usages,
  'recoveries': recoveries,
};

Map<String, dynamic> _equipped(String id, {Object? usages = 2}) => {
  'usages': usages,
  'spell': _known(id),
};

Map<String, dynamic> _status({
  Object? known = const <Object?>[],
  Object? states,
}) => {
  'maxActiveSpells': 2,
  'spells': known,
  if (states != null) 'spellStates': states,
};

Map<String, dynamic> _assets(Object? equipped) => {'activeSpells': equipped};

List<Map<String, dynamic>> _built(Map<String, dynamic> status, Object? assets) {
  final built = statusJsonWithLegacySpellStates(status, assets)['spellStates'];
  return (built as List).cast<Map<String, dynamic>>();
}

void main() {
  test(
    'builds one state per known spell in the order of the known list (D-15)',
    () {
      final known = [_known('s-1'), _known('s-2'), _known('s-3')];

      final built = _built(_status(known: known), _assets(const <Object?>[]));

      expect(built.map((state) => state['spell']), known);
      expect(built, hasLength(3));
    },
  );

  test('marks as active the spells of the equipped list (D-15)', () {
    final built = _built(
      _status(known: [_known('s-1'), _known('s-2'), _known('s-3')]),
      _assets([_equipped('s-3'), _equipped('s-1')]),
    );

    expect(built.map((state) => (state['spell'] as Map)['id']), [
      's-1',
      's-2',
      's-3',
    ]);
    expect(built.map((state) => state['active']), [true, false, true]);
  });

  test(
    'takes usages and recoveries from the legacy state of the same spell (D-15)',
    () {
      final built = _built(
        _status(
          known: [_known('s-1'), _known('s-2')],
          states: [
            _state(
              's-2',
              usages: 0,
              recoveries: const [
                '2026-10-27T10:02:00.000Z',
                '2026-10-27T10:30:00.000Z',
              ],
            ),
            _state('s-1', usages: 1),
          ],
        ),
        _assets([_equipped('s-2', usages: 2)]),
      );

      expect(built[0]['usages'], 1);
      expect(built[0]['recoveries'], ['2026-10-27T10:12:00.000Z']);
      expect(built[1]['usages'], 0);
      expect(built[1]['recoveries'], [
        '2026-10-27T10:02:00.000Z',
        '2026-10-27T10:30:00.000Z',
      ]);
    },
  );

  test(
    'falls back to the equipped usages, then to the catalogue maximum, then to zero (D-15)',
    () {
      final built = _built(
        _status(
          known: [
            _known('equipped', maxUsages: 5),
            _known('catalogue', maxUsages: 4),
            _known('nothing', maxUsages: null),
            _known('unreadable-state', maxUsages: 6),
          ],
          states: [_state('unreadable-state', usages: 'x', recoveries: 'x')],
        ),
        _assets([
          _equipped('equipped', usages: 2),
          _equipped('catalogue', usages: null),
        ]),
      );

      expect(built.map((state) => state['usages']), [2, 4, 0, 6]);
      expect(built.map((state) => state['recoveries']), everyElement(isEmpty));
    },
  );

  test('a status without the known list is returned unchanged (D-15)', () {
    final newShape = <String, dynamic>{
      'maxActiveSpells': 2,
      'spellStates': [
        {
          'spell': _known('s-1'),
          'usages': 1,
          'recoveries': <Object?>[],
          'active': true,
        },
      ],
    };

    expect(
      identical(
        statusJsonWithLegacySpellStates(newShape, _assets([_equipped('s-1')])),
        newShape,
      ),
      isTrue,
    );

    final nullKnown = <String, dynamic>{'spells': null};
    expect(
      identical(statusJsonWithLegacySpellStates(nullKnown, null), nullKnown),
      isTrue,
    );
  });

  test('does not mutate its inputs (D-15)', () {
    Map<String, dynamic> status() =>
        _status(known: [_known('s-1'), _known('s-2')], states: [_state('s-1')]);
    Map<String, dynamic> assets() => _assets([_equipped('s-2')]);
    final statusInput = status();
    final assetsInput = assets();

    final built = statusJsonWithLegacySpellStates(statusInput, assetsInput);

    expect(identical(built, statusInput), isFalse);
    expect(statusInput, status());
    expect(assetsInput, assets());
    expect(built['maxActiveSpells'], 2);
    expect(built['spells'], statusInput['spells']);
  });

  test('never throws on a partial or malformed payload (D-15)', () {
    final known = [_known('s-1')];
    final payloads = <String, (Map<String, dynamic>, Object?)>{
      'assets null': (_status(known: known), null),
      'assets not a map': (_status(known: known), 'assets'),
      'assets without the equipped list': (
        _status(known: known),
        <String, dynamic>{},
      ),
      'equipped list not a list': (_status(known: known), _assets('equipped')),
      'legacy states not a list': (
        _status(known: known, states: 'states'),
        _assets(const <Object?>[]),
      ),
      'a legacy state that is not a map or has no spell': (
        _status(
          known: known,
          states: [
            'state',
            null,
            {'usages': 1},
            {'spell': 's-1'},
            {
              'spell': {'id': 7},
            },
          ],
        ),
        _assets(const <Object?>[]),
      ),
      'an equipped entry without a spell': (
        _status(known: known),
        _assets([
          {'usages': 2},
          {'usages': 2, 'spell': null},
          {
            'usages': 2,
            'spell': {'name': 'senza id'},
          },
          'equipped',
          null,
        ]),
      ),
    };

    for (final MapEntry(key: name, value: (status, assets))
        in payloads.entries) {
      final built = _built(status, assets);

      expect(built, hasLength(1), reason: name);
      expect(built.single['spell'], known.single, reason: name);
      expect(built.single['usages'], 3, reason: name);
      expect(built.single['recoveries'], isEmpty, reason: name);
      expect(built.single['active'], isFalse, reason: name);
    }

    final skipped = _built(
      _status(
        known: [
          'spell',
          null,
          7,
          {'name': 'senza id'},
          {'id': 7},
          _known('s-1'),
        ],
      ),
      null,
    );
    expect(skipped.map((state) => (state['spell'] as Map)['id']), ['s-1']);
  });

  test(
    'the built status parses into active states with their spells (D-05, D-15)',
    () {
      final status = CharacterStatus.fromJson(
        statusJsonWithLegacySpellStates(
          _status(
            known: [
              _known('s-1', name: 'Scudo'),
              _known('s-2', name: 'Dardo'),
              _known('s-3', name: 'Lampo', maxUsages: 4),
            ],
            states: [_state('s-1', usages: 1)],
          ),
          _assets([_equipped('s-2', usages: 2), _equipped('s-1', usages: 3)]),
        ),
      );

      final states = status.spellStates;
      expect(states.map((state) => state.spellId), ['s-1', 's-2', 's-3']);
      expect(states.map((state) => state.active), [true, true, false]);
      expect(states.map((state) => state.spell.name), [
        'Scudo',
        'Dardo',
        'Lampo',
      ]);
      expect(states.map((state) => state.usages), [1, 2, 4]);
      expect(states.first.recoveries, [DateTime.utc(2026, 10, 27, 10, 12)]);
      expect(states.last.recoveries, isEmpty);
      expect(status.maxActiveSpells, 2);
    },
  );
}
