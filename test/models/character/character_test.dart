import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/character/character.dart';

import '../../helpers/fixtures/spell_fixtures.dart';

Map<String, dynamic> _spell(String id, String name) => {
  'id': id,
  'name': name,
  'description': 'Una magia di prova',
  'maxUsages': 3,
};

/// Chiave della lista di magie conosciute prima della BE Phase 19.
const _knownListKey = 'spells';

/// Chiave della lista di magie equipaggiate prima della BE Phase 19.
const _equippedListKey =
    'active'
    'Spells';

void main() {
  group('Character.fromJson spells', () {
    test('a payload with the legacy spell lists is not translated '
        '(D-05, D-15)', () {
      final character = Character.fromJson({
        'id': 'c-1',
        'status': {
          'maxActiveSpells': 2,
          _knownListKey: [_spell('s-1', 'Dardo'), _spell('s-2', 'Scudo')],
          'spellStates': [
            {
              'spell': {'id': 's-2'},
              'usages': 1,
              'recoveries': ['2026-10-27T10:12:00.000Z'],
            },
          ],
        },
        'assets': {
          _equippedListKey: [
            {
              'usages': 2,
              'spell': {'id': 's-2'},
            },
          ],
        },
      });

      final state = character.status!.spellStates.single;
      expect(state.spellId, 's-2');
      expect(state.spell.name, isNull);
      expect(state.active, isFalse);
      expect(state.usages, 1);
      expect(state.recoveries, [DateTime.utc(2026, 10, 27, 10, 12)]);
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
        'still parses (D-05)', () {
      final statusOnly = Character.fromJson({
        'id': 'c-1',
        'status': {
          'spellStates': [spellStateJson(active: true)],
        },
      });
      final assetsOnly = Character.fromJson({
        'id': 'c-2',
        'assets': <String, dynamic>{},
      });
      final neither = Character.fromJson({'id': 'c-3'});

      expect(statusOnly.status!.spellStates.single.active, isTrue);
      expect(statusOnly.assets, isNull);
      expect(assetsOnly.status, isNull);
      expect(assetsOnly.assets, isNotNull);
      expect(neither.status, isNull);
      expect(neither.assets, isNull);
    });
  });
}
