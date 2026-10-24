import 'dart:math' as math;

import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';

/// Polilinea del viaggio misurata una volta (D-06): lunghezze cumulative planari
/// sui gradi, uguali alle lunghezze a schermo sulla mappa Epsg4326.
class TravelRoute extends Equatable {
  const TravelRoute._(this.points, this.cumulative);

  factory TravelRoute.of(List<LatLng> points) {
    final distinct = <LatLng>[];
    for (final point in points) {
      if (distinct.isEmpty || distinct.last != point) distinct.add(point);
    }
    final cumulative = <double>[];
    for (var i = 0; i < distinct.length; i++) {
      cumulative.add(
        i == 0 ? 0 : cumulative[i - 1] + _length(distinct[i - 1], distinct[i]),
      );
    }
    return TravelRoute._(
      List.unmodifiable(distinct),
      List.unmodifiable(cumulative),
    );
  }

  final List<LatLng> points;
  final List<double> cumulative;

  bool get isEmpty => points.isEmpty;
  double get totalLength => cumulative.isEmpty ? 0 : cumulative.last;

  /// Punto alla frazione [progress] della lunghezza (clamp 0..1); `null` se vuota.
  LatLng? pointAt(double progress) {
    if (isEmpty) return null;
    if (totalLength == 0) return points.first;
    final target = _targetLength(progress);
    final i = _segmentIndexAt(target);
    final t =
        (target - cumulative[i - 1]) / (cumulative[i] - cumulative[i - 1]);
    return _lerp(points[i - 1], points[i], t);
  }

  /// Tratto percorso e tratto rimanente, entrambi contenenti il punto corrente.
  ({List<LatLng> travelled, List<LatLng> remaining}) splitAt(double progress) {
    if (isEmpty) return (travelled: const [], remaining: const []);
    if (totalLength == 0) {
      return (travelled: [points.first], remaining: [points.first]);
    }
    final i = _segmentIndexAt(_targetLength(progress));
    final current = pointAt(progress)!;
    return (
      travelled: [
        ...points.sublist(0, i),
        if (current != points[i - 1]) current,
      ],
      remaining: [if (current != points[i]) current, ...points.sublist(i)],
    );
  }

  double _targetLength(double progress) =>
      progress.clamp(0, 1).toDouble() * totalLength;

  int _segmentIndexAt(double target) {
    for (var i = 1; i < cumulative.length; i++) {
      if (cumulative[i] >= target) return i;
    }
    return cumulative.length - 1;
  }

  static LatLng _lerp(LatLng a, LatLng b, double t) {
    if (t <= 0) return a;
    if (t >= 1) return b;
    return LatLng(
      a.latitude + (b.latitude - a.latitude) * t,
      a.longitude + (b.longitude - a.longitude) * t,
    );
  }

  static double _length(LatLng a, LatLng b) {
    final dLat = b.latitude - a.latitude;
    final dLon = b.longitude - a.longitude;
    return math.sqrt(dLat * dLat + dLon * dLon);
  }

  @override
  List<Object?> get props => [points];
}

/// D-07: frazione del viaggio sull'ora del server stimata, mai sull'orologio
/// del device. `durationMs ≤ 0` vale arrivo (nessuna divisione per zero).
double travelProgress({
  required DateTime serverNow,
  required DateTime startTime,
  required double durationMs,
}) {
  if (durationMs <= 0) return 1;
  final elapsed = serverNow.difference(startTime).inMilliseconds;
  return (elapsed / durationMs).clamp(0, 1).toDouble();
}
