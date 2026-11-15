import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/config/cloudinary_assets.dart';
import 'package:klimmeck_guide/models/enums/city_type.dart';

void main() {
  test('only Talmvere keeps its marker visible at every zoom (D-13)', () {
    expect(CityType.values.where((type) => type.alwaysVisible), [
      CityType.talmvereVillage,
    ]);
  });

  test('the two new capitals use the Talmvere marker size (D-16)', () {
    expect(CityType.aarakocraCapital.size, 39);
    expect(CityType.dragonbornCapital.size, 39);
    expect(CityType.aarakocraCapital.size, CityType.talmvereVillage.size);
    expect(CityType.dragonbornCapital.size, CityType.talmvereVillage.size);
  });

  test('the dragonborn village uses the village marker size (D-16)', () {
    expect(CityType.dragonbornVillage.size, 30);
    expect(CityType.dragonbornVillage.size, CityType.aarakocraVillage.size);
  });

  test('the three new markers point to their files (D-17, D-21)', () {
    expect(
      CloudinaryAssets.aarakocraCapital,
      'v1794764223/aarakocraCapital_affl5r.svg',
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
      CityType.aarakocraCapital.imagePath,
      CloudinaryAssets.url(CloudinaryAssets.aarakocraCapital),
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

  test('the aarakocra village is drawn with its new file (D-17, D-21)', () {
    expect(
      CloudinaryAssets.aarakocraVillage,
      'v1794764202/aarakocraVillage_z7n1rz.svg',
    );
    expect(CityType.aarakocraVillage.size, 30);
    expect(
      CityType.aarakocraVillage.imagePath,
      CloudinaryAssets.url(CloudinaryAssets.aarakocraVillage),
    );
  });

  test(
    'the village and the capital of the aarakocra are two different drawings (D-17)',
    () {
      expect(
        CloudinaryAssets.aarakocraVillage,
        isNot(CloudinaryAssets.aarakocraCapital),
      );
    },
  );
}
