import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/utils/pour_geometry.dart';
import 'package:klimmeck_guide/utils/pour_simulation.dart';

const List<Offset> _bottle = [
  Offset(40, 0),
  Offset(40, 40),
  Offset(0, 40),
  Offset(0, 140),
  Offset(100, 140),
  Offset(100, 40),
  Offset(60, 40),
  Offset(60, 0),
];

PourSimulation _simulation({
  Set<PourSide> sides = const {PourSide.character, PourSide.companion},
}) => PourSimulation(
  geometry: PourGeometry(
    interior: _bottle,
    mouth: const Offset(50, 0),
    pivot: const Offset(50, 90),
  ),
  sides: sides,
);

const Duration _frame = Duration(milliseconds: 16);

/// Fa avanzare la simulazione e raccoglie i lati impegnati.
List<PourSide> _run(PourSimulation simulation, Duration duration) {
  final committed = <PourSide>[];
  for (var t = Duration.zero; t < duration; t += _frame) {
    if (simulation.step(_frame) case final side?) committed.add(side);
  }
  return committed;
}

void main() {
  group('PourSimulation', () {
    test('starts upright and partly full', () {
      final simulation = _simulation();
      expect(simulation.angle, 0);
      expect(simulation.fill, PourSimulation.startFill);
      expect(simulation.committedSide, isNull);
    });

    test('follows the aim and settles back upright once released before '
        'the first drop, with nothing poured', () {
      final simulation = _simulation()..aim(0.5);
      expect(_run(simulation, const Duration(seconds: 1)), isEmpty);
      expect(simulation.angle, closeTo(0.5, 0.05));
      simulation.aim(0);
      _run(simulation, const Duration(seconds: 2));
      expect(simulation.angle, closeTo(0, 0.02));
      expect(simulation.fill, PourSimulation.startFill);
      expect(simulation.committedSide, isNull);
    });

    test('a clockwise tilt past the first drop commits to the character once '
        'and pours the bottle empty even if the aim comes back', () {
      final simulation = _simulation()..aim(PourSimulation.maxTilt);
      final committed = _run(simulation, const Duration(milliseconds: 1500));
      expect(committed, [PourSide.character]);
      simulation.aim(0);
      _run(simulation, const Duration(seconds: 6));
      expect(simulation.isEmpty, isTrue);
      expect(simulation.committedSide, PourSide.character);
    });

    test('a counter-clockwise tilt commits to the companion', () {
      final simulation = _simulation()..aim(-PourSimulation.maxTilt);
      expect(_run(simulation, const Duration(milliseconds: 1500)), [
        PourSide.companion,
      ]);
    });

    test('the aim never goes past the maximum tilt', () {
      final simulation = _simulation()..aim(10);
      _run(simulation, const Duration(seconds: 1));
      expect(
        simulation.angle,
        lessThanOrEqualTo(PourSimulation.maxTilt + 0.05),
      );
    });

    test('toward a side with no drinker the bottle stops before pouring', () {
      final simulation = _simulation(sides: const {PourSide.companion})
        ..aim(PourSimulation.maxTilt);
      expect(_run(simulation, const Duration(seconds: 2)), isEmpty);
      expect(simulation.angle, closeTo(PourSimulation.refusedTilt, 0.05));
      expect(simulation.fill, PourSimulation.startFill);
    });

    test('a sudden tilt makes the surface slosh, then it calms down', () {
      final simulation = _simulation()..aim(0.6);
      _run(simulation, const Duration(milliseconds: 150));
      expect(simulation.slosh.abs(), greaterThan(0.01));
      _run(simulation, const Duration(seconds: 4));
      expect(simulation.slosh.abs(), lessThan(0.01));
    });

    test('is settled only while upright and still', () {
      final simulation = _simulation();
      expect(simulation.isSettled, isTrue);
      simulation.aim(0.5);
      _run(simulation, const Duration(milliseconds: 100));
      expect(simulation.isSettled, isFalse);
      simulation.aim(0);
      _run(simulation, const Duration(seconds: 5));
      expect(simulation.isSettled, isTrue);
    });

    test('the level reads the current tilt and fill', () {
      final simulation = _simulation()..aim(math.pi / 4);
      _run(simulation, const Duration(seconds: 1));
      expect(simulation.level.liquid, isNotEmpty);
      expect(simulation.level.isSpilling, isFalse);
    });
  });
}
