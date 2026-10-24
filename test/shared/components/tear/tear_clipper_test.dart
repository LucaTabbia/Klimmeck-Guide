import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/shared/components/tear/tear_clipper.dart';

void main() {
  group('TearClipper', () {
    const size = Size(200, 400);

    test('edge spans the full width around 10% of the height', () {
      final edge = TearClipper.edgePoints(size);
      expect(edge.first.dx, 0);
      expect(edge.last.dx, 200);
      for (final point in edge) {
        expect(point.dy, inInclusiveRange(400 * 0.075, 400 * 0.125));
      }
    });

    test('same seed gives the same edge', () {
      expect(
        TearClipper.edgePoints(size, seed: 7),
        TearClipper.edgePoints(size, seed: 7),
      );
    });

    test('different seeds give different edges', () {
      expect(
        TearClipper.edgePoints(size, seed: 1),
        isNot(TearClipper.edgePoints(size, seed: 2)),
      );
    });

    test('step widths and depths are irregular', () {
      final edge = TearClipper.edgePoints(size, seed: 3);
      final gaps = <double>{};
      final depths = <double>{};
      for (var i = 1; i < edge.length; i++) {
        gaps.add((edge[i].dx - edge[i - 1].dx).roundToDouble());
        depths.add(((edge[i].dy - 40).abs() * 10).roundToDouble());
      }
      expect(gaps.length, greaterThan(1));
      expect(depths.length, greaterThan(1));
    });

    test('stub and body clips cover opposite sides of the cut', () {
      final stub = const TearClipper(piece: TearPiece.stub).getClip(size);
      final body = const TearClipper(piece: TearPiece.body).getClip(size);
      expect(stub.contains(const Offset(100, 8)), isTrue);
      expect(stub.contains(const Offset(100, 200)), isFalse);
      expect(body.contains(const Offset(100, 200)), isTrue);
      expect(body.contains(const Offset(100, 8)), isFalse);
    });

    test('shouldReclip only when piece or seed changes', () {
      const stub = TearClipper(piece: TearPiece.stub);
      expect(
        stub.shouldReclip(const TearClipper(piece: TearPiece.stub)),
        isFalse,
      );
      expect(
        stub.shouldReclip(const TearClipper(piece: TearPiece.body)),
        isTrue,
      );
      expect(
        stub.shouldReclip(const TearClipper(piece: TearPiece.stub, seed: 1)),
        isTrue,
      );
    });

    test('seedOf is stable and id-dependent', () {
      expect(TearClipper.seedOf('h-1'), TearClipper.seedOf('h-1'));
      expect(TearClipper.seedOf('h-1'), isNot(TearClipper.seedOf('h-2')));
      expect(TearClipper.seedOf('h-1'), greaterThanOrEqualTo(0));
    });
  });
}
