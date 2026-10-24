import 'package:equatable/equatable.dart';
import 'package:klimmeck_guide/models/wire_lat_lng.dart';
import 'package:latlong2/latlong.dart';

/// Polilinea orientata dalla partenza alla meta (BE Phase 8 D-10), distanza in km di gioco.
class TravelPath extends Equatable {
  const TravelPath({required this.points, required this.distance});

  final List<LatLng> points;
  final double distance;

  factory TravelPath.fromJson(Map<String, dynamic> json) {
    final coordinates = json['coordinates'];
    return TravelPath(
      points: List.unmodifiable(
        coordinates is List
            ? coordinates.map(tryLatLngFromWire).whereType<LatLng>()
            : const <LatLng>[],
      ),
      distance: (json['distance'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'coordinates': [
      for (final point in points) [point.latitude, point.longitude],
    ],
    'distance': distance,
  };

  @override
  List<Object?> get props => [points, distance];
}
