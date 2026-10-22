import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/shared/components/tear/tear_geometry.dart';

void main() {
  group('TearGeometry', () {
    test('is at rest at progress 0', () {
      final pose = TearGeometry.at(0, 400);
      expect(pose.stub.dx, 0);
      expect(pose.stub.angle, 0);
      expect(pose.body.dx, 0);
      expect(pose.body.angle, 0);
    });

    test('the stub never moves', () {
      for (final progress in [0.0, 0.25, 0.5, 1.0]) {
        for (final exit in [0.0, 0.5, 1.0]) {
          final pose = TearGeometry.at(progress, 400, exit: exit);
          expect(pose.stub.dx, 0);
          expect(pose.stub.angle, 0);
        }
      }
    });

    test('the body follows the finger left', () {
      var previous = TearGeometry.at(0, 400);
      for (final progress in [0.25, 0.5, 1.0]) {
        final pose = TearGeometry.at(progress, 400);
        expect(pose.body.dx, lessThan(previous.body.dx));
        expect(pose.body.angle, lessThan(previous.body.angle));
        previous = pose;
      }
      expect(previous.body.dx, greaterThan(-400));
    });

    test('the exit pushes the body past the exit distance', () {
      expect(
        TearGeometry.at(1, 400, exit: 1).body.dx,
        lessThanOrEqualTo(-400 * 1.15),
      );
      expect(
        TearGeometry.at(1, 400, exit: 1, exitDistance: 780).body.dx,
        lessThanOrEqualTo(-780),
      );
      final a = TearGeometry.at(1, 400).body.dx;
      final b = TearGeometry.at(1, 400, exit: 0.5).body.dx;
      final c = TearGeometry.at(1, 400, exit: 1).body.dx;
      expect(b, lessThan(a));
      expect(c, lessThan(b));
    });
  });
}
