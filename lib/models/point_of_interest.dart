import 'package:equatable/equatable.dart';
import 'package:klimmeck_guide/models/wire_lat_lng.dart';
import 'package:latlong2/latlong.dart';

import 'city.dart';
import 'enums/poi_type.dart';

class PointOfInterest extends Equatable {
  const PointOfInterest({
    required this.id,
    required this.type,
    required this.location,
    required this.city,
  });

  final String id;
  final List<PoiType>? type;
  final LatLng? location;
  final City? city;

  factory PointOfInterest.fromJson(Map<String, dynamic> json) {
    return PointOfInterest(
      id: json["id"] as String,
      type: poiTypesFrom(json['type']),
      location: _locationFrom(json['location']),
      city: json["city"] != null ? City.fromJson(json['city']) : null,
    );
  }

  /// Posizione assente, nulla o con la prima coordinata nulla: `null`. Ogni
  /// altra forma passa dal lettore stretto (un POI rotto deve emergere).
  static LatLng? _locationFrom(Object? json) {
    if (json == null) return null;
    final wire = json as List<dynamic>;
    if (wire.isNotEmpty && wire.first == null) return null;
    return latLngFromWire(wire);
  }

  Map<String, dynamic> toJson() => {
    "id": id,
    "type": type?.map((s) => s.name).toList(),
    "location": location != null
        ? [location?.latitude, location?.longitude]
        : null,
    "city": city?.toJson(),
  };

  PointOfInterest copyWith({
    String? id,
    List<PoiType>? type,
    LatLng? location,
    dynamic city,
  }) {
    return PointOfInterest(
      id: id ?? this.id,
      type: type ?? this.type,
      location: location ?? this.location,
      city: city ?? this.city,
    );
  }

  @override
  List<Object?> get props => [id, type, location, city];
}
