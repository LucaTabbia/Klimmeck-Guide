import 'package:flutter/widgets.dart';

enum TearSide { left, right }

/// Taglio verticale frastagliato a metà foglio, deterministico (mai Random):
/// le due metà condividono lo stesso bordo.
class TearClipper extends CustomClipper<Path> {
  const TearClipper({required this.side});

  final TearSide side;
  static const int teeth = 14;
  static const double toothDepth = 0.04;

  static List<Offset> edgePoints(Size size) => [
    for (var i = 0; i <= teeth; i++)
      Offset(
        size.width * (0.5 + (i.isEven ? -toothDepth : toothDepth)),
        size.height * i / teeth,
      ),
  ];

  @override
  Path getClip(Size size) {
    final edge = edgePoints(size);
    final outerX = side == TearSide.left ? 0.0 : size.width;
    final path = Path()..moveTo(outerX, 0);
    for (final point in edge) {
      path.lineTo(point.dx, point.dy);
    }
    return path
      ..lineTo(outerX, size.height)
      ..close();
  }

  @override
  bool shouldReclip(TearClipper oldClipper) => oldClipper.side != side;
}
