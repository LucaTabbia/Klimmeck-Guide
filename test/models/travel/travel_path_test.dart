import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/point_of_interest.dart';
import 'package:klimmeck_guide/models/travel/travel_path.dart';
import 'package:latlong2/latlong.dart';

import '../../helpers/fixtures/travel_fixtures.dart';

void main() {
  final path = TravelPath.fromJson(travelPathJson());

  test('fromJson reads the points in order and the distance', () {
    expect(path.points, [LatLng(10, 20), LatLng(11, 21), LatLng(12, 23)]);
    expect(path.distance, 15.8);
  });

  test('malformed points are dropped and valid ones kept in order', () {
    final json = travelPathJson()
      ..['coordinates'] = [
        [10.0, 20.0],
        [1.0],
        'x',
        [95.0, 0.0],
        [12.0, 23.0],
      ];
    expect(TravelPath.fromJson(json).points, [LatLng(10, 20), LatLng(12, 23)]);
  });

  test('missing or non-list coordinates give no points', () {
    expect(TravelPath.fromJson({'distance': 1.0}).points, isEmpty);
    expect(
      TravelPath.fromJson({'coordinates': 'x', 'distance': 1.0}).points,
      isEmpty,
    );
  });

  test('toJson round trips', () {
    expect(TravelPath.fromJson(path.toJson()), path);
  });

  test('equality is on points and distance', () {
    expect(path, TravelPath.fromJson(travelPathJson()));
    expect(path == TravelPath.fromJson(travelPathJson(distance: 1)), isFalse);
  });

  test('points are unmodifiable', () {
    expect(() => path.points.add(LatLng(0, 0)), throwsUnsupportedError);
  });

  test('C1: route endpoints equal the departure and destination POIs', () {
    final departure = PointOfInterest.fromJson({
      'id': 'city-marker-1',
      'location': departureWire,
    });
    final destination = PointOfInterest.fromJson({
      'id': 'city-marker-2',
      'location': destinationWire,
    });
    expect(path.points.first, departure.location);
    expect(path.points.last, destination.location);
  });
}
