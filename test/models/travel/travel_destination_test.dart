import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/city.dart';
import 'package:klimmeck_guide/models/point_of_interest.dart';
import 'package:klimmeck_guide/models/travel/travel_destination.dart';

PointOfInterest poi(String id) => PointOfInterest.fromJson({
  'id': id,
  'location': [1.0, 2.0],
});

City city(String id, {String? markerId}) => City.fromJson({
  'id': id,
  'markerLocation': markerId == null
      ? null
      : {
          'id': markerId,
          'location': [1.0, 2.0],
        },
});

void main() {
  final cityA = city('city-a', markerId: 'marker-a');
  final cityB = city('city-b', markerId: 'marker-b');
  final markerOfCityA = poi('marker-a');

  test('another city is the destination (D-01)', () {
    expect(travelDestinationFor(target: cityB, location: markerOfCityA), cityB);
  });

  test('the city the character stands on is no destination (D-02)', () {
    expect(
      travelDestinationFor(target: cityA, location: markerOfCityA),
      isNull,
    );
  });

  test('no target is no destination', () {
    expect(travelDestinationFor(target: null, location: markerOfCityA), isNull);
  });

  test('a city without a marker is no destination', () {
    expect(
      travelDestinationFor(target: city('city-c'), location: markerOfCityA),
      isNull,
    );
  });

  test('an unknown location leaves the judgement to the backend', () {
    expect(travelDestinationFor(target: cityB, location: null), cityB);
  });
}
