import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/travel/travel_preview.dart';

import '../../helpers/fixtures/travel_fixtures.dart';

void main() {
  final preview = TravelPreview.fromJson(travelPreviewJson());

  test('fromJson reads distance, duration and road', () {
    expect(preview.distance, 15.8);
    expect(preview.duration, 9600000);
    expect(preview.road.points, hasLength(3));
  });

  test('toJson round trips', () {
    expect(TravelPreview.fromJson(preview.toJson()), preview);
  });

  test('equality covers every field', () {
    expect(preview, TravelPreview.fromJson(travelPreviewJson()));
    expect(
      preview == TravelPreview.fromJson(travelPreviewJson(duration: 1)),
      isFalse,
    );
  });
}
