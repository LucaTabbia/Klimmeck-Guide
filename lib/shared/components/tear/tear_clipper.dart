import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// stub = striscia in alto che resta, body = pezzo inferiore che se ne va.
enum TearPiece { stub, body }

/// Taglio orizzontale frastagliato al 10% dell'altezza, deterministico per seed
/// (mai Random non seminato): stub e body condividono lo stesso bordo.
class TearClipper extends CustomClipper<Path> {
  const TearClipper({required this.piece, this.seed = 0});

  final TearPiece piece;
  final int seed;

  static const double tearRatio = 0.10;
  static const double minStep = 0.015;
  static const double maxStep = 0.06;
  static const double maxJag = 0.025;
  static const double minJagShare = 0.2;

  /// Hash stabile (String.hashCode non è garantito stabile tra esecuzioni).
  static int seedOf(String id) =>
      id.codeUnits.fold(17, (hash, unit) => (hash * 31 + unit) & 0x3fffffff);

  static List<Offset> edgePoints(Size size, {int seed = 0}) {
    final random = math.Random(seed);
    final baseY = size.height * tearRatio;
    if (size.width <= 0) {
      return [Offset(0, baseY), Offset(size.width, baseY)];
    }
    final points = <Offset>[Offset(0, baseY)];
    var x = 0.0;
    var isUp = random.nextBool();
    while (x < size.width) {
      x = math.min(
        size.width,
        x + size.width * (minStep + random.nextDouble() * (maxStep - minStep)),
      );
      final depth =
          size.height *
          maxJag *
          (minJagShare + (1 - minJagShare) * random.nextDouble());
      points.add(Offset(x, baseY + (isUp ? -depth : depth)));
      if (random.nextDouble() < 0.8) isUp = !isUp;
    }
    return points;
  }

  @override
  Path getClip(Size size) {
    final edge = edgePoints(size, seed: seed);
    final outerY = piece == TearPiece.stub ? 0.0 : size.height;
    final path = Path()
      ..moveTo(0, outerY)
      ..lineTo(size.width, outerY);
    for (final point in edge.reversed) {
      path.lineTo(point.dx, point.dy);
    }
    return path..close();
  }

  @override
  bool shouldReclip(TearClipper oldClipper) =>
      oldClipper.piece != piece || oldClipper.seed != seed;
}
