import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/enums/lore_type.dart';
import 'package:klimmeck_guide/models/lore.dart';

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
}
