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

  test('the board is disabled away from a city marker', () {
    expect(disabledSatchelPages(location: poi('quest-poi'), cities: cities), {
      SatchelLayout.boardPageIndex,
    });
  });

  test('on a city marker nothing is disabled', () {
    expect(
      disabledSatchelPages(location: poi('city-marker-1'), cities: cities),
      isEmpty,
    );
  });

  test('unknown location or no cities disables the board', () {
    expect(disabledSatchelPages(location: null, cities: cities), {4});
    expect(
      disabledSatchelPages(location: poi('city-marker-1'), cities: const []),
      {4},
    );
  });

  test('boardPageIndex is the page of the Bacheca entry', () {
    final board = SatchelLayout.entries.firstWhere((e) => e.label == 'Bacheca');
    expect(SatchelLayout.boardPageIndex, 4);
    expect(board.pageIndex, SatchelLayout.boardPageIndex);
  });
}
