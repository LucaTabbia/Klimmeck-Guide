import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/utils/pour_geometry.dart';

/// Boccetta quadrata 100 × 100 con un collo 20 × 40 al centro in alto:
/// la bocca sta in (50, 0).
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
const Offset _mouth = Offset(50, 0);
const Offset _pivot = Offset(50, 90);

PourGeometry _geometry() =>
    PourGeometry(interior: _bottle, mouth: _mouth, pivot: _pivot);

double _area(List<Offset> polygon) {
  var sum = 0.0;
  for (var i = 0; i < polygon.length; i++) {
    final a = polygon[i];
    final b = polygon[(i + 1) % polygon.length];
    sum += a.dx * b.dy - b.dx * a.dy;
  }
  return sum.abs() / 2;
}

void main() {
  group('PourGeometry', () {
    test('measures the inside of the bottle', () {
      expect(_geometry().area, closeTo(100 * 100 + 20 * 40, 1e-6));
    });

    test('an upright half-full bottle has a level surface across the body', () {
      final level = _geometry().levelOf(angle: 0, fill: 0.5);
      final half = (100 * 100 + 20 * 40) / 2;
      expect(level.surfaceY, closeTo(140 - half / 100, 1e-3));
      expect(_area(level.liquid), closeTo(half, 1e-2));
      expect(level.isSpilling, isFalse);
    });

    test('keeps the same volume whatever the tilt', () {
      final geometry = _geometry();
      for (final degrees in [15, 45, 80, 110]) {
        final level = geometry.levelOf(
          angle: degrees * math.pi / 180,
          fill: 0.3,
        );
        expect(
          _area(level.liquid),
          closeTo(geometry.area * 0.3, geometry.area * 0.002),
          reason: '$degrees°',
        );
      }
    });

    test('the surface stays horizontal: every liquid point is below it', () {
      final level = _geometry().levelOf(angle: math.pi / 3, fill: 0.4);
      for (final point in level.liquid) {
        expect(point.dy, greaterThanOrEqualTo(level.surfaceY - 1e-6));
      }
    });

    test('spills only once the mouth is below the surface', () {
      final geometry = _geometry();
      expect(
        geometry.levelOf(angle: math.pi / 4, fill: 0.5).isSpilling,
        isFalse,
      );
      expect(
        geometry.levelOf(angle: math.pi * 0.75, fill: 0.5).isSpilling,
        isTrue,
      );
    });

    test('tilting left mirrors tilting right', () {
      final geometry = _geometry();
      final right = geometry.levelOf(angle: math.pi / 2, fill: 0.5);
      final left = geometry.levelOf(angle: -math.pi / 2, fill: 0.5);
      expect(left.surfaceY, closeTo(right.surfaceY, 1e-3));
      expect(left.mouth.dx, closeTo(2 * _pivot.dx - right.mouth.dx, 1e-6));
    });

    test('an empty bottle has no liquid', () {
      final level = _geometry().levelOf(angle: 1, fill: 0);
      expect(level.liquid, isEmpty);
      expect(level.isSpilling, isFalse);
    });
  });
}
