import 'package:flutter/material.dart';
import 'package:klimmeck_guide/shared/components/cached_svg.dart';

class MenuItem extends StatelessWidget {
  const MenuItem({
    super.key,
    required this.itemAnimationController,
    required this.pageIndex,
    required this.itemSize,
    required this.showItems,
    required this.imagePath,
    required this.end,
    required this.onTap,
  });

  final AnimationController itemAnimationController;
  final int pageIndex;
  final double itemSize;
  final bool showItems;
  final String imagePath;

  /// Centro della cella d'arrivo nel frame dello Stack (vedi SatchelLayout.flightEnd).
  final Offset end;
  final ValueChanged<int> onTap;

  List<double> _parabolaCoefficients(
    Offset start,
    Offset end,
    double apexHeight,
  ) {
    double x0 = start.dx, y0 = start.dy;
    double x2 = end.dx, y2 = end.dy;
    double xm = (x0 + x2) / 2;
    double ym = apexHeight;

    double a =
        ((y2 - y0) * (x0 - xm) - (ym - y0) * (x0 - x2)) /
        ((x2 * x2 - x0 * x0) * (x0 - xm) - (xm * xm - x0 * x0) * (x0 - x2));
    double b = (ym - y0 - a * (xm * xm - x0 * x0)) / (xm - x0);
    double c = y0 - a * x0 * x0 - b * x0;

    return [a, b, c];
  }

  Offset _pointOnParabola(double x, List<double> coefficients) {
    double a = coefficients[0], b = coefficients[1], c = coefficients[2];
    double y = a * x * x + b * x + c;
    return Offset(x, y);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: itemAnimationController,
      builder: (context, child) {
        final start = Offset(
          25,
          -(MediaQuery.of(context).size.height / 2) + 50,
        );

        final coefficients = _parabolaCoefficients(
          start,
          end,
          -(MediaQuery.of(context).size.height / 2 + 100),
        );
        double progress = itemAnimationController.value;
        double x = start.dx + (end.dx - start.dx) * progress;
        Offset pos = _pointOnParabola(x, coefficients);

        return Transform.translate(
          offset: pos,
          child: GestureDetector(
            onTap: () => onTap(pageIndex),
            child: AnimatedContainer(
              duration: Duration(milliseconds: 300),
              width: showItems ? itemSize : 0,
              height: showItems ? itemSize : 0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,

                boxShadow: [
                  BoxShadow(
                    color: Colors.black45,
                    blurRadius: 7,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: CachedSvg(url: imagePath),
            ),
          ),
        );
      },
    );
  }
}
