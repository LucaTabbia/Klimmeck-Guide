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

City shoplessCity(String markerId) => City.fromJson({
  'id': 'city-necrorian',
  'hasShop': false,
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

  test('on a city marker while awaiting aid board and shop are disabled', () {
    expect(
      disabledSatchelPages(
        location: poi('city-marker-1'),
        cities: cities,
        isTravelling: false,
        isAwaitingAid: true,
      ),
      boardAndShop,
    );
  });

  test('on a city marker not awaiting aid nothing is disabled', () {
    expect(
      disabledSatchelPages(
        location: poi('city-marker-1'),
        cities: cities,
        isTravelling: false,
        isAwaitingAid: false,
      ),
      isEmpty,
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

  group('city shop flag', () {
    final shopless = [shoplessCity('necrorian-marker')];

    test('a city without a shop disables only the Shop page (D-04)', () {
      expect(
        disabledSatchelPages(
          location: poi('necrorian-marker'),
          cities: shopless,
          isTravelling: false,
        ),
        {SatchelLayout.shopPageIndex},
      );
    });

    test('a city without a shop keeps the Board page open (D-04)', () {
      expect(
        disabledSatchelPages(
          location: poi('necrorian-marker'),
          cities: shopless,
          isTravelling: false,
        ),
        isNot(contains(SatchelLayout.boardPageIndex)),
      );
    });

    test(
      'a city without a shop while travelling disables Board and Shop (Phase 7 D-12)',
      () {
        expect(
          disabledSatchelPages(
            location: poi('necrorian-marker'),
            cities: shopless,
            isTravelling: true,
          ),
          boardAndShop,
        );
      },
    );

    test(
      'a city without a shop while awaiting aid disables Board and Shop (Phase 9 D-16)',
      () {
        expect(
          disabledSatchelPages(
            location: poi('necrorian-marker'),
            cities: shopless,
            isTravelling: false,
            isAwaitingAid: true,
          ),
          boardAndShop,
        );
      },
    );

    test('a city with hasShop true keeps every page open (D-04)', () {
      final withShop = City.fromJson({
        'id': 'city-talmvere',
        'hasShop': true,
        'markerLocation': {
          'id': 'talmvere-marker',
          'location': [1.0, 2.0],
        },
      });
      expect(
        disabledSatchelPages(
          location: poi('talmvere-marker'),
          cities: [withShop],
          isTravelling: false,
        ),
        isEmpty,
      );
    });
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
