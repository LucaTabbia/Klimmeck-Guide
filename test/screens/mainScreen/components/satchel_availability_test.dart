import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/city.dart';
import 'package:klimmeck_guide/models/point_of_interest.dart';
import 'package:klimmeck_guide/screens/mainScreen/components/satchel_availability.dart';
import 'package:klimmeck_guide/screens/mainScreen/components/satchel_layout.dart';

PointOfInterest poi(String id) => PointOfInterest.fromJson({
  'id': id,
  'location': [1.0, 2.0],
});

City city(String markerId) => City.fromJson({
  'id': 'city-1',
  'markerLocation': {
    'id': markerId,
    'location': [1.0, 2.0],
  },
});

void main() {
  final cities = [city('city-marker-1')];
  const boardAndShop = {
    SatchelLayout.boardPageIndex,
    SatchelLayout.shopPageIndex,
  };

  test('board and shop are disabled away from a city marker', () {
    expect(
      disabledSatchelPages(
        location: poi('quest-poi'),
        cities: cities,
        isTravelling: false,
      ),
      boardAndShop,
    );
  });

  test('on a city marker without a travel nothing is disabled', () {
    expect(
      disabledSatchelPages(
        location: poi('city-marker-1'),
        cities: cities,
        isTravelling: false,
      ),
      isEmpty,
    );
  });

  test('on a city marker while travelling board and shop are disabled', () {
    expect(
      disabledSatchelPages(
        location: poi('city-marker-1'),
        cities: cities,
        isTravelling: true,
      ),
      boardAndShop,
    );
  });

  test('unknown location or no cities disables board and shop', () {
    expect(
      disabledSatchelPages(location: null, cities: cities, isTravelling: false),
      {4, 5},
    );
    expect(
      disabledSatchelPages(
        location: poi('city-marker-1'),
        cities: const [],
        isTravelling: false,
      ),
      {4, 5},
    );
  });

  test('boardPageIndex is the page of the Bacheca entry', () {
    final board = SatchelLayout.entries.firstWhere((e) => e.label == 'Bacheca');
    expect(SatchelLayout.boardPageIndex, 4);
    expect(board.pageIndex, SatchelLayout.boardPageIndex);
  });

  test('shopPageIndex is the page of the Negozio entry', () {
    final shop = SatchelLayout.entries.firstWhere((e) => e.label == 'Negozio');
    expect(SatchelLayout.shopPageIndex, 5);
    expect(shop.pageIndex, SatchelLayout.shopPageIndex);
  });
}
