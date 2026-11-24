import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/config/cloudinary_assets.dart';
import 'package:klimmeck_guide/models/enums/city_type.dart';

void main() {
  test('only Talmvere keeps its marker visible at every zoom (D-13)', () {
    expect(CityType.values.where((type) => type.alwaysVisible), [
      CityType.talmvereVillage,
    ]);
  });

  test('the two new capitals stand a little larger than Talmvere (D-16)', () {
    expect(CityType.volucriCapital.size, 46);
    expect(CityType.dragonbornCapital.size, 46);
    expect(
      CityType.volucriCapital.size,
      greaterThan(CityType.talmvereVillage.size),
    );
  });

  test('the dragonborn village uses the village marker size (D-16)', () {
    expect(CityType.dragonbornVillage.size, 30);
    expect(CityType.dragonbornVillage.size, CityType.volucriVillage.size);
  });

  test('the three new markers point to their files (D-17, D-21)', () {
    expect(
      CloudinaryAssets.volucriCapital,
      'v1795548614/main/cities/volucriCapital.svg',
    );
    expect(
      CloudinaryAssets.dragonbornCapital,
      'v1794764233/dragonbornCapital_uyedhh.svg',
    );
    expect(
      CloudinaryAssets.dragonbornVillage,
      'v1794764212/dragonbornVillage_doclsu.svg',
    );
    expect(
      CityType.volucriCapital.imagePath,
      CloudinaryAssets.url(CloudinaryAssets.volucriCapital),
    );
    expect(
      CityType.dragonbornCapital.imagePath,
      CloudinaryAssets.url(CloudinaryAssets.dragonbornCapital),
    );
    expect(
      CityType.dragonbornVillage.imagePath,
      CloudinaryAssets.url(CloudinaryAssets.dragonbornVillage),
    );
  });

  test('the volucri village is drawn with its new file (D-17, D-21)', () {
    expect(
      CloudinaryAssets.volucriVillage,
      'v1795548609/main/cities/volucriVillage.svg',
    );
    expect(CityType.volucriVillage.size, 30);
    expect(
      CityType.volucriVillage.imagePath,
      CloudinaryAssets.url(CloudinaryAssets.volucriVillage),
    );
  });

  test(
    'the village and the capital of the volucri are two different drawings (D-17)',
    () {
      expect(
        CloudinaryAssets.volucriVillage,
        isNot(CloudinaryAssets.volucriCapital),
      );
    },
  );
}
