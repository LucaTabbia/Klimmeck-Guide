import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/character/race_traits.dart';
import 'package:klimmeck_guide/models/enums/race_type.dart';

void main() {
  const elfJson = {'race': 'elf', 'minAge': 100, 'maxAge': 9999};
  const elf = RaceTraits(race: RaceType.elf, minAge: 100, maxAge: 9999);

  test('fromJson parses race and age bounds', () {
    expect(RaceTraits.fromJson(elfJson), elf);
  });

  test('toJson round-trips', () {
    expect(RaceTraits.fromJson(elf.toJson()), elf);
    expect(elf.toJson(), elfJson);
  });

  test('tryFromJson skips an unknown race', () {
    expect(
      RaceTraits.tryFromJson({'race': 'centaur', 'minAge': 1, 'maxAge': 2}),
      isNull,
    );
  });

  test('tryFromJson skips a non numeric age', () {
    expect(
      RaceTraits.tryFromJson({'race': 'elf', 'minAge': 'old', 'maxAge': 2}),
      isNull,
    );
  });

  test('allows is inclusive on both bounds', () {
    expect(elf.allows(100), isTrue);
    expect(elf.allows(9999), isTrue);
    expect(elf.allows(99), isFalse);
    expect(elf.allows(10000), isFalse);
  });
}
