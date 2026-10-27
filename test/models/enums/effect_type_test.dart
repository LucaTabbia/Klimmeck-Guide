import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/enums/effect_type.dart';

void main() {
  test('effects have an Italian label', () {
    expect(EffectType.none.label, 'Nessun effetto');
    expect(EffectType.heal.label, 'Cura');
    expect(EffectType.hunger.label, 'Sazietà');
    expect(EffectType.munition.label, 'Danno');
    expect(EffectType.exploration.label, 'Esplorazione');
  });

  test('order and byName keep working', () {
    expect(EffectType.values.map((e) => e.name), [
      'none',
      'heal',
      'hunger',
      'munition',
      'exploration',
    ]);
    expect(EffectType.values.byName('heal'), EffectType.heal);
  });
}
