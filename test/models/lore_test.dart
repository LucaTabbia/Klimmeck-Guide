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
    'imagePath': null,
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

  test('parses the image from the imagePath key (D-06)', () {
    final lore = Lore.fromJson({'id': 'l', 'imagePath': 'https://x/y.svg'});

    expect(lore.toJson()['imagePath'], 'https://x/y.svg');
  });

  test('the old image key is no longer read (D-06)', () {
    final lore = Lore.fromJson({'id': 'l', 'image': 'https://x/y.svg'});

    expect(lore.toJson()['imagePath'], isNull);
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

  group('lenientRefsFrom', () {
    test('keeps the entries with an id and a name (D-16)', () {
      final refs = Lore.lenientRefsFrom([
        loreRefJson(
          id: 'lore-limit',
          name: 'Il limite del corpo',
          type: 'knowledge',
        ),
      ]);

      expect(refs, hasLength(1));
      expect(refs.single.id, 'lore-limit');
      expect(refs.single.name, 'Il limite del corpo');
      expect(refs.single.type, LoreType.knowledge);
    });

    test('drops entries without id or without name and non-maps (D-16)', () {
      final refs = Lore.lenientRefsFrom([
        {'name': 'x'},
        {'id': 'a'},
        {'id': 'b', 'name': ''},
        42,
        loreRefJson(),
      ]);

      expect(refs, [Lore.fromJson(loreRefJson())]);
    });

    test('anything but a list is an empty list (D-16)', () {
      expect(Lore.lenientRefsFrom(null), isEmpty);
      expect(Lore.lenientRefsFrom('lore'), isEmpty);
      expect(Lore.lenientRefsFrom(<String, dynamic>{}), isEmpty);
    });

    test('an unknown type is kept with a null type (D-16)', () {
      final refs = Lore.lenientRefsFrom([loreRefJson(type: 'dragon')]);

      expect(refs.single.id, 'lore-goblin');
      expect(refs.single.type, isNull);
    });
  });
}
