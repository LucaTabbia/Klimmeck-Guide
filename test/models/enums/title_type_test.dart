import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/enums/title_type.dart';

void main() {
  test('titles have an Italian label', () {
    expect(TitleType.rookie.label, 'Recluta');
    expect(TitleType.adventurer.label, 'Avventuriero');
    expect(TitleType.paladin.label, 'Paladino');
    expect(TitleType.mage.label, 'Mago');
    expect(TitleType.hero.label, 'Eroe');
    expect(TitleType.legend.label, 'Leggenda');
  });

  test('order and byName keep working', () {
    expect(TitleType.values.map((t) => t.name), [
      'rookie',
      'adventurer',
      'paladin',
      'mage',
      'hero',
      'legend',
    ]);
    expect(TitleType.values.byName('mage'), TitleType.mage);
  });
}
