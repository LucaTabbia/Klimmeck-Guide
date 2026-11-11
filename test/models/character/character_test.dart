import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/character/character.dart';

import '../../helpers/fixtures/spell_fixtures.dart';

Map<String, dynamic> _spell(String id, String name) => {
  'id': id,
  'name': name,
  'description': 'Una magia di prova',
  'maxUsages': 3,
};

void main() {
  group('Character.fromJson spells', () {
    test('a payload of the BE of today yields states with their spells and '
        'active flags (D-15)', () {
      final character = Character.fromJson({
        'id': 'c-1',
        'status': {
          'maxActiveSpells': 2,
          'spells': [_spell('s-1', 'Dardo'), _spell('s-2', 'Scudo')],
          'spellStates': [
            {
              'spell': {'id': 's-2'},
              'usages': 1,
              'recoveries': ['2026-10-27T10:12:00.000Z'],
            },
          ],
        },
        'assets': {
          'activeSpells': [
            {
              'usages': 2,
              'spell': {'id': 's-2'},
            },
          ],
        },
      });

      final states = character.status!.spellStates;
      expect(states.map((state) => state.spellId), ['s-1', 's-2']);
      expect(states.map((state) => state.spell.name), ['Dardo', 'Scudo']);
      expect(states.map((state) => state.active), [false, true]);
      expect(states.map((state) => state.usages), [3, 1]);
      expect(states[1].recoveries, [DateTime.utc(2026, 10, 27, 10, 12)]);
    });

    test('a payload in the Phase 19 shape is read as served (D-05)', () {
      final character = Character.fromJson({
        'id': 'c-1',
        'status': {
          'maxActiveSpells': 2,
          'spellStates': [spellStateJson(active: true)],
        },
        'assets': <String, dynamic>{},
      });

      final state = character.status!.spellStates.single;
      expect(state.active, isTrue);
      expect(state.spellId, 'spell-1');
      expect(state.usages, 1);
    });

    test('a character with a status only, with assets only or with neither '
        'still parses (D-15)', () {
      final statusOnly = Character.fromJson({
        'id': 'c-1',
        'status': {
          'spells': [_spell('s-1', 'Dardo')],
        },
      });
      final assetsOnly = Character.fromJson({
        'id': 'c-2',
        'assets': {
          'activeSpells': [
            {
              'usages': 2,
              'spell': {'id': 's-1'},
            },
          ],
        },
      });
      final neither = Character.fromJson({'id': 'c-3'});

      expect(statusOnly.status!.spellStates.single.active, isFalse);
      expect(statusOnly.status!.spellStates.single.usages, 3);
      expect(statusOnly.assets, isNull);
      expect(assetsOnly.status, isNull);
      expect(assetsOnly.assets, isNotNull);
      expect(neither.status, isNull);
      expect(neither.assets, isNull);
    });
  });
}
