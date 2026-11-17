import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/config/cloudinary_assets.dart';
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

  test('every title has its own badge on Cloudinary', () {
    expect(TitleType.values.map((title) => title.badgePath), [
      CloudinaryAssets.url(CloudinaryAssets.rookieRank),
      CloudinaryAssets.url(CloudinaryAssets.adventurerRank),
      CloudinaryAssets.url(CloudinaryAssets.paladinRank),
      CloudinaryAssets.url(CloudinaryAssets.mageRank),
      CloudinaryAssets.url(CloudinaryAssets.heroRank),
      CloudinaryAssets.url(CloudinaryAssets.legendRank),
    ]);
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
