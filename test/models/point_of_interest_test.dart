import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/point_of_interest.dart';
import 'package:latlong2/latlong.dart';

void main() {
  final poi = PointOfInterest.fromJson({
    'id': 'p',
    'location': [10.0, 20.0],
  });

  test('location is read in the wire order', () {
    expect(poi.location, LatLng(10.0, 20.0));
  });

  test('toJson emits the location in the wire order', () {
    expect(poi.toJson()['location'], [10.0, 20.0]);
  });
}
