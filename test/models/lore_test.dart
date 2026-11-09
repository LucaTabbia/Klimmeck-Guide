import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/enums/lore_type.dart';
import 'package:klimmeck_guide/models/lore.dart';

import '../helpers/fixtures/lore_fixtures.dart';

void main() {
  const json = {
    'id': 'l1',
    'type': 'city',
    'name': 'Talmvere',
    'description': 'Un villaggio',
    'image': null,
    'relatedLore': [
      {'id': 'l2', 'name': 'Drustea'},
    ],
  };

  test('reads the fields the lore query selects', () {
    final lore = Lore.fromJson(json);
    expect(lore.id, 'l1');
    expect(lore.type, LoreType.city);
    expect(lore.name, 'Talmvere');
    expect(lore.description, 'Un villaggio');
    expect(lore.relatedLore?.single.id, 'l2');
  });

  test('ignores an unlocked key left by an older backend', () {
    final lore = Lore.fromJson({...json, 'unlocked': true});
    expect(lore, Lore.fromJson(json));
  });

  test('does not serialize unlocked (BE Phase 11, D-25)', () {
    expect(Lore.fromJson(json).toJson().keys, isNot(contains('unlocked')));
  });

  test('round trips its wire type (D-15)', () {
    final lore = Lore.fromJson(loreJson(type: 'enemy', name: 'Goblin'));
    expect(lore.toJson()['type'], 'enemy');
    expect(Lore.fromJson(lore.toJson()), lore);
  });

  test(
    'reads an unknown or missing type as null and keeps the entry (D-16)',
    () {
      final payloads = [
        loreJson(type: 'dragon'),
        loreJson()..remove('type'),
        loreJson()..['type'] = 42,
      ];
      for (final payload in payloads) {
        final lore = Lore.fromJson(payload);
        expect(lore.type, isNull, reason: '$payload');
        expect(lore.id, 'lore-1');
        expect(lore.name, 'Talmvere');
      }
    },
  );
}
