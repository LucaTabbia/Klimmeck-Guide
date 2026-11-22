import 'dart:math' as math;
import 'dart:ui';

/// Dove disegnare la freccia che indica una pedina fuori schermo e di quanto
/// ruotarla (l'asset punta verso il basso).
typedef PawnPointer = ({Offset position, double angle});

/// Distanza della freccia dal bordo dello schermo e dall'angolo coperto.
const double pawnPointerInset = 50;

/// `null` con la pedina a schermo. Altrimenti la freccia sta sulla linea fra il
/// centro dello schermo e la pedina, a [inset] dal bordo (UAT 2026-11-14).
///
/// [coveredCorner] è la parte dell'angolo in basso a sinistra nascosta dal
/// borsello: una pedina lì sotto conta come fuori schermo e la freccia si ferma
/// a [inset] da quella zona.
PawnPointer? pawnPointerFor({
  required Size viewport,
  required Offset pawn,
  double inset = pawnPointerInset,
  Size coveredCorner = Size.zero,
}) {
  final covered = Rect.fromLTRB(
    0,
    viewport.height - coveredCorner.height,
    coveredCorner.width,
    viewport.height,
  );
  final isVisible =
      (Offset.zero & viewport).contains(pawn) && !covered.contains(pawn);
  if (isVisible) return null;

  final centre = viewport.center(Offset.zero);
  final toPawn = pawn - centre;
  final reach = [
    _reachAlong(toPawn.dx, viewport.width / 2 - inset),
    _reachAlong(toPawn.dy, viewport.height / 2 - inset),
    if (!covered.isEmpty) _reachInto(covered.inflate(inset), centre, toPawn),
  ].reduce(math.min);
  return (
    position: centre + toPawn * reach,
    angle: math.atan2(toPawn.dy, toPawn.dx) - math.pi / 2,
  );
}

/// Frazione del tratto verso la pedina che resta dentro [halfExtent].
double _reachAlong(double delta, double halfExtent) =>
    delta == 0 ? double.infinity : halfExtent / delta.abs();

/// Frazione del tratto da [origin] lungo [direction] percorsa prima di entrare
/// in [zone]; infinita se il tratto non la incontra.
double _reachInto(Rect zone, Offset origin, Offset direction) {
  final (enterX, exitX) = _crossing(
    origin.dx,
    direction.dx,
    zone.left,
    zone.right,
  );
  final (enterY, exitY) = _crossing(
    origin.dy,
    direction.dy,
    zone.top,
    zone.bottom,
  );
  final enter = math.max(enterX, enterY);
  final exit = math.min(exitX, exitY);
  if (enter > exit || exit < 0) return double.infinity;
  return math.max(enter, 0);
}

/// Intervallo del parametro in cui `start + delta * t` sta fra [low] e [high].
(double, double) _crossing(
  double start,
  double delta,
  double low,
  double high,
) {
  if (delta == 0) {
    final isInside = start >= low && start <= high;
    return isInside
        ? (double.negativeInfinity, double.infinity)
        : (double.infinity, double.negativeInfinity);
  }
  final atLow = (low - start) / delta;
  final atHigh = (high - start) / delta;
  return (math.min(atLow, atHigh), math.max(atLow, atHigh));
}
