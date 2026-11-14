import 'dart:math' as math;
import 'dart:ui';

/// Dove disegnare la freccia che indica una pedina fuori schermo e di quanto
/// ruotarla (l'asset punta verso il basso).
typedef PawnPointer = ({Offset position, double angle});

/// Distanza della freccia dal bordo dello schermo.
const double pawnPointerInset = 50;

/// `null` con la pedina a schermo. Altrimenti la freccia sta sulla linea fra il
/// centro dello schermo e la pedina, a [inset] dal bordo (UAT 2026-11-14).
PawnPointer? pawnPointerFor({
  required Size viewport,
  required Offset pawn,
  double inset = pawnPointerInset,
}) {
  if ((Offset.zero & viewport).contains(pawn)) return null;
  final centre = viewport.center(Offset.zero);
  final toPawn = pawn - centre;
  final reach = math.min(
    _reachAlong(toPawn.dx, viewport.width / 2 - inset),
    _reachAlong(toPawn.dy, viewport.height / 2 - inset),
  );
  return (
    position: centre + toPawn * reach,
    angle: math.atan2(toPawn.dy, toPawn.dx) - math.pi / 2,
  );
}

/// Frazione del tratto verso la pedina che resta dentro [halfExtent].
double _reachAlong(double delta, double halfExtent) =>
    delta == 0 ? double.infinity : halfExtent / delta.abs();
