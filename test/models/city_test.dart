import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/city.dart';
import 'package:klimmeck_guide/models/enums/city_size_type.dart';
import 'package:klimmeck_guide/models/enums/city_type.dart';

void main() {
  group('City', () {
    test('parses size village, city and capital from the backend (D-04)', () {
      expect(
        City.fromJson({'id': 'c', 'size': 'village'}).size,
        CitySizeType.village,
      );
      expect(
        City.fromJson({'id': 'c', 'size': 'city'}).size,
        CitySizeType.city,
      );
      expect(
        City.fromJson({'id': 'c', 'size': 'capital'}).size,
        CitySizeType.capital,
      );
    });

    test('leaves an unknown size null instead of throwing (D-15)', () {
      expect(City.fromJson({'id': 'c', 'size': 'metropolis'}).size, isNull);
      expect(City.fromJson({'id': 'c'}).size, isNull);
    });

    test('a city without the flag keeps its shop (wire default, D-15)', () {
      expect(City.fromJson({'id': 'c'}).hasShop, isTrue);
    });

    test('parses hasShop false for a city with an empty pool (D-04)', () {
      expect(City.fromJson({'id': 'c', 'hasShop': false}).hasShop, isFalse);
    });
  });

  group('City.tryFromJson (Phase 19)', () {
    test('returns the city for a readable map (D-16)', () {
      final city = City.tryFromJson({
        'id': 'c',
        'type': 'drusteaCapital',
        'name': 'Cliffbreak',
      });

      expect(city?.id, 'c');
      expect(city?.type, CityType.drusteaCapital);
      expect(city?.name, 'Cliffbreak');
    });

    test('a city with an unknown type is null (D-16)', () {
      expect(City.tryFromJson({'id': 'c', 'type': 'floatingCitadel'}), isNull);
    });

    test('a value that is not a map is null (D-16)', () {
      expect(City.tryFromJson('c'), isNull);
      expect(City.tryFromJson(null), isNull);
      expect(City.tryFromJson(const ['c']), isNull);
    });

    test('City.fromJson stays strict on an unknown type (D-16)', () {
      expect(
        () => City.fromJson({'id': 'c', 'type': 'floatingCitadel'}),
        throwsArgumentError,
      );
    });
  });
}
