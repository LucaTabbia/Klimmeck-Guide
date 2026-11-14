import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/map/utils/pawn_pointer.dart';

void main() {
  const viewport = Size(800, 400);

  group('pawnPointerFor (UAT 2026-11-14)', () {
    test('a pawn on the screen needs no pointer', () {
      expect(
        pawnPointerFor(viewport: viewport, pawn: const Offset(10, 390)),
        isNull,
      );
      expect(
        pawnPointerFor(viewport: viewport, pawn: const Offset(400, 200)),
        isNull,
      );
    });

    test(
      'a pawn off to the right is pointed at from 50 px inside the edge',
      () {
        final pointer = pawnPointerFor(
          viewport: viewport,
          pawn: const Offset(2000, 200),
        )!;

        expect(pointer.position, const Offset(750, 200));
        // la freccia è disegnata verso il basso: a destra ruota di -90°
        expect(pointer.angle, moreOrLessEquals(-math.pi / 2, epsilon: 1e-9));
      },
    );

    test('a pawn below is pointed at without turning the arrow', () {
      final pointer = pawnPointerFor(
        viewport: viewport,
        pawn: const Offset(400, 5000),
      )!;

      expect(pointer.position, const Offset(400, 350));
      expect(pointer.angle, moreOrLessEquals(0, epsilon: 1e-9));
    });

    test('a pawn above turns the arrow upside down', () {
      final pointer = pawnPointerFor(
        viewport: viewport,
        pawn: const Offset(400, -300),
      )!;

      expect(pointer.position, const Offset(400, 50));
      expect(pointer.angle.abs(), moreOrLessEquals(math.pi, epsilon: 1e-9));
    });

    test('a pawn off a corner keeps the pointer on the line to the pawn, '
        'inside the inset frame', () {
      final pointer = pawnPointerFor(
        viewport: viewport,
        pawn: const Offset(1200, 600),
      )!;

      // direzione (800, 400) dal centro: tocca insieme i due bordi rientrati
      expect(pointer.position.dx, moreOrLessEquals(700, epsilon: 1e-6));
      expect(pointer.position.dy, moreOrLessEquals(350, epsilon: 1e-6));
    });

    test('a pawn just off the left edge stays 50 px from it', () {
      final pointer = pawnPointerFor(
        viewport: viewport,
        pawn: const Offset(-1, 120),
      )!;

      expect(pointer.position.dx, moreOrLessEquals(50, epsilon: 1e-6));
      expect(pointer.position.dy, inInclusiveRange(50, 350));
    });
  });
}
