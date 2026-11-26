import 'dart:math' as math;
import 'dart:ui';

/// Il liquido di una boccetta inclinata (Phase 26 D-05): la boccetta ruota
/// attorno a [pivot], il liquido resta sotto un pelo orizzontale e ne
/// conserva il volume. Coordinate dello schermo (y verso il basso).
class PourGeometry {
  PourGeometry({
    required List<Offset> interior,
    required this.mouth,
    required this.pivot,
  }) : interior = List.unmodifiable(interior),
       area = _areaOf(interior);

  /// Sagoma interna della boccetta dritta, dalla bocca al fondo.
  final List<Offset> interior;

  /// Centro dell'apertura della boccetta dritta.
  final Offset mouth;

  /// Punto attorno a cui la boccetta ruota.
  final Offset pivot;

  /// Superficie interna: il volume di una boccetta piena.
  final double area;

  static const int _searchSteps = 40;

  /// Il liquido a inclinazione [angle] (radianti, positivo = orario) con la
  /// boccetta piena per la frazione [fill] (0..1).
  LiquidLevel levelOf({required double angle, required double fill}) {
    final rotated = [for (final point in interior) _rotate(point, angle)];
    final mouthNow = _rotate(mouth, angle);
    if (fill <= 0) {
      return LiquidLevel(
        liquid: const [],
        surfaceY: double.infinity,
        mouth: mouthNow,
      );
    }
    final target = area * fill.clamp(0, 1);
    var top = rotated.map((point) => point.dy).reduce(math.min);
    var bottom = rotated.map((point) => point.dy).reduce(math.max);
    for (var step = 0; step < _searchSteps; step++) {
      final middle = (top + bottom) / 2;
      if (_areaOf(_below(rotated, middle)) > target) {
        top = middle;
      } else {
        bottom = middle;
      }
    }
    final surfaceY = (top + bottom) / 2;
    return LiquidLevel(
      liquid: _below(rotated, surfaceY),
      surfaceY: surfaceY,
      mouth: mouthNow,
    );
  }

  Offset _rotate(Offset point, double angle) {
    final dx = point.dx - pivot.dx;
    final dy = point.dy - pivot.dy;
    final cos = math.cos(angle);
    final sin = math.sin(angle);
    return Offset(
      pivot.dx + dx * cos - dy * sin,
      pivot.dy + dx * sin + dy * cos,
    );
  }

  /// Sutherland–Hodgman sul semipiano y ≥ [surfaceY].
  static List<Offset> _below(List<Offset> polygon, double surfaceY) {
    final clipped = <Offset>[];
    for (var i = 0; i < polygon.length; i++) {
      final current = polygon[i];
      final next = polygon[(i + 1) % polygon.length];
      final isCurrentIn = current.dy >= surfaceY;
      final isNextIn = next.dy >= surfaceY;
      if (isCurrentIn) clipped.add(current);
      if (isCurrentIn != isNextIn) {
        final t = (surfaceY - current.dy) / (next.dy - current.dy);
        clipped.add(Offset(current.dx + (next.dx - current.dx) * t, surfaceY));
      }
    }
    return clipped;
  }

  static double _areaOf(List<Offset> polygon) {
    var sum = 0.0;
    for (var i = 0; i < polygon.length; i++) {
      final a = polygon[i];
      final b = polygon[(i + 1) % polygon.length];
      sum += a.dx * b.dy - b.dx * a.dy;
    }
    return sum.abs() / 2;
  }
}

/// Il liquido in un istante: il poligono sotto il pelo, l'altezza del pelo e
/// la bocca, tutto già ruotato.
class LiquidLevel {
  const LiquidLevel({
    required this.liquid,
    required this.surfaceY,
    required this.mouth,
  });

  final List<Offset> liquid;
  final double surfaceY;
  final Offset mouth;

  /// La bocca sta sotto il pelo: il liquido esce.
  bool get isSpilling => liquid.isNotEmpty && mouth.dy > surfaceY;
}
