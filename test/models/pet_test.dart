import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/pet.dart';

import '../helpers/fixtures/shop_fixtures.dart';

void main() {
  group('Pet', () {
    test('parses speedModifier as a double from an int or a float (D-11)', () {
      expect(Pet.fromJson(petJson(speedModifier: 2)).speedModifier, 2.0);
      expect(Pet.fromJson(petJson(speedModifier: 2.5)).speedModifier, 2.5);
    });

    test(
      'leaves speedModifier null for a companion that is not a mount (D-07)',
      () {
        expect(Pet.fromJson(catPetJson()).speedModifier, isNull);
      },
    );

    test('parses sellable from the wire (D-09)', () {
      expect(Pet.fromJson(petJson(sellable: true)).sellable, isTrue);
      expect(Pet.fromJson(petJson(sellable: false)).sellable, isFalse);
      expect(Pet.fromJson(petJson()..remove('sellable')).sellable, isNull);
    });

    test('lists speedModifier and sellable in props', () {
      expect(
        Pet.fromJson(petJson(speedModifier: 2)),
        isNot(Pet.fromJson(petJson(speedModifier: 2.5))),
      );
      expect(
        Pet.fromJson(petJson(sellable: true)),
        isNot(Pet.fromJson(petJson(sellable: false))),
      );
    });
  });
}
