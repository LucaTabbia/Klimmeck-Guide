import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/enums/lore_type.dart';

void main() {
  test('labels every type in Italian (D-15)', () {
    expect(LoreType.enemy.label, 'Mostri');
    expect(LoreType.animal.label, 'Animali');
    expect(LoreType.plant.label, 'Piante');
    expect(LoreType.character.label, 'Personaggi');
    expect(LoreType.city.label, 'Città');
    expect(LoreType.region.label, 'Regioni');
    expect(LoreType.state.label, 'Stati');
    expect(LoreType.religion.label, 'Religioni');
    expect(LoreType.ceremony.label, 'Cerimonie');
    expect(LoreType.god.label, 'Divinità');
    expect(LoreType.material.label, 'Materiali');
    expect(LoreType.knowledge.label, 'Conoscenze');
  });

  test('keeps the wire name of every type (D-15)', () {
    expect(LoreType.values.map((type) => type.name), [
      'enemy',
      'animal',
      'plant',
      'character',
      'city',
      'region',
      'state',
      'religion',
      'ceremony',
      'god',
      'material',
      'knowledge',
    ]);
  });

  test('only enemies, animals and plants are Bestiario pages (D-10, D-15)', () {
    const bestiary = {LoreType.enemy, LoreType.animal, LoreType.plant};
    for (final type in LoreType.values) {
      expect(type.isBestiary, bestiary.contains(type), reason: type.name);
    }
  });
}
