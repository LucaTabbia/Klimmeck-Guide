import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/city.dart';
import 'package:klimmeck_guide/models/enums/city_size_type.dart';

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
}
