import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/shared/components/tear/tear_clipper.dart';
import 'package:klimmeck_guide/shared/components/tear/tear_geometry.dart';

void main() {
  group('TearGeometry', () {
    test('is at rest at progress 0', () {
      final pose = TearGeometry.at(0, 400);
      expect(pose.left.dx, 0);
      expect(pose.left.angle, 0);
      expect(pose.right.dx, 0);
      expect(pose.right.angle, 0);
    });

    test('moves the halves apart as progress grows', () {
      var previous = TearGeometry.at(0, 400);
      for (final progress in [0.25, 0.5, 1.0]) {
        final pose = TearGeometry.at(progress, 400);
        expect(pose.left.dx, lessThan(previous.left.dx));
        expect(pose.left.angle, lessThan(previous.left.angle));
        expect(pose.right.dx, greaterThan(previous.right.dx));
        expect(pose.right.angle, greaterThan(previous.right.angle));
        previous = pose;
      }
    });
  });

  group('TearClipper', () {
    const size = Size(200, 400);

    test('edge is deterministic and spans the height near the middle', () {
      final first = TearClipper.edgePoints(size);
      expect(TearClipper.edgePoints(size), first);
      expect(first.first.dy, 0);
      expect(first.last.dy, 400);
      for (final point in first) {
        expect(point.dx, inInclusiveRange(200 * 0.45, 200 * 0.55));
      }
    });

    test('left and right clips cover opposite sides', () {
      final left = const TearClipper(side: TearSide.left).getClip(size);
      final right = const TearClipper(side: TearSide.right).getClip(size);
      expect(left.contains(const Offset(20, 200)), isTrue);
      expect(left.contains(const Offset(180, 200)), isFalse);
      expect(right.contains(const Offset(180, 200)), isTrue);
      expect(right.contains(const Offset(20, 200)), isFalse);
    });

    test('shouldReclip only when side changes', () {
      const left = TearClipper(side: TearSide.left);
      expect(
        left.shouldReclip(const TearClipper(side: TearSide.left)),
        isFalse,
      );
      expect(
        left.shouldReclip(const TearClipper(side: TearSide.right)),
        isTrue,
      );
    });
  });
}
