import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/pet.dart';
import 'package:klimmeck_guide/shared/components/cards/companion_details_gesture.dart';

import '../../../helpers/fixtures/shop_fixtures.dart';

void main() {
  void openDetails() {}

  test('a known companion keeps the long press that opens its details '
      '(D-22, UAT 2026-11-15)', () {
    final pet = Pet.fromJson(petJson(known: true));

    expect(companionDetailsGesture(pet, openDetails), openDetails);
  });

  test('a companion whose lore is not unlocked has no long press '
      '(UAT 2026-11-15)', () {
    final pet = Pet.fromJson(petJson(known: false));

    expect(companionDetailsGesture(pet, openDetails), isNull);
  });

  test('no opener stays no opener (UAT 2026-11-15)', () {
    expect(companionDetailsGesture(Pet.fromJson(petJson()), null), isNull);
  });
}
