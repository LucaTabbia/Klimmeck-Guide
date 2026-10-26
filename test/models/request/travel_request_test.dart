import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/request/travel_request.dart';

void main() {
  group('TravelRequest', () {
    test('serialises the character id as id and the marker id as poiId', () {
      const request = TravelRequest(id: 'c-1', poiId: 'city-marker-2');

      expect(request.toJson(), {'id': 'c-1', 'poiId': 'city-marker-2'});
    });

    test('is equal by id and poiId', () {
      expect(
        const TravelRequest(id: 'c-1', poiId: 'city-marker-2'),
        const TravelRequest(id: 'c-1', poiId: 'city-marker-2'),
      );
      expect(
        const TravelRequest(id: 'c-1', poiId: 'city-marker-2'),
        isNot(const TravelRequest(id: 'c-1', poiId: 'city-marker-3')),
      );
    });
  });
}
