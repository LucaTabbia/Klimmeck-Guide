import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/enums/damage_type.dart';
import 'package:klimmeck_guide/models/enums/energy_type.dart';
import 'package:klimmeck_guide/models/weaknesses.dart';

void main() {
  test('parses base and energy names in the served order (D-01)', () {
    final weaknesses = Weaknesses.fromJson(const {
      'base': ['cut', 'blunt'],
      'energy': ['fire'],
    });

    expect(weaknesses.base, [DamageType.cut, DamageType.blunt]);
    expect(weaknesses.energy, [EnergyType.fire]);
  });

  test('drops a name this client does not know (D-01)', () {
    final weaknesses = Weaknesses.fromJson(const {
      'base': ['cut', 'laser'],
      'energy': ['plasma'],
    });

    expect(weaknesses.base, [DamageType.cut]);
    expect(weaknesses.energy, isEmpty);
  });

  test('a missing or malformed value is the empty value (D-01)', () {
    for (final Object? malformed in [
      null,
      'x',
      42,
      <String, dynamic>{},
      <String, dynamic>{'base': 'cut', 'energy': null},
    ]) {
      expect(
        Weaknesses.fromJson(malformed),
        const Weaknesses(),
        reason: '$malformed',
      );
    }
  });

  test('toJson round-trips the names (D-01)', () {
    const json = {
      'base': ['pierce'],
      'energy': ['cold', 'acid'],
    };

    final weaknesses = Weaknesses.fromJson(json);

    expect(weaknesses.toJson(), json);
    expect(Weaknesses.fromJson(weaknesses.toJson()), weaknesses);
  });

  test('is equal by value and lists are unmodifiable (D-01)', () {
    const json = {
      'base': ['cut'],
      'energy': ['fire'],
    };
    final weaknesses = Weaknesses.fromJson(json);

    expect(
      weaknesses,
      const Weaknesses(base: [DamageType.cut], energy: [EnergyType.fire]),
    );
    expect(weaknesses, isNot(const Weaknesses(base: [DamageType.cut])));
    expect(() => weaknesses.base.add(DamageType.blunt), throwsUnsupportedError);
    expect(
      () => weaknesses.energy.add(EnergyType.cold),
      throwsUnsupportedError,
    );
  });
}
