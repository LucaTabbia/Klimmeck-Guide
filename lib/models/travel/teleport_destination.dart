import 'package:equatable/equatable.dart';
import 'package:klimmeck_guide/models/city.dart';
import 'package:klimmeck_guide/models/enums/poi_type.dart';
import 'package:klimmeck_guide/models/point_of_interest.dart';
import 'package:latlong2/latlong.dart';

/// Luogo dove l'oste può teletrasportare il gruppo (D-01): il marker di una
/// città o un luogo interno (rovine, foreste…) con un punto sulla mappa.
class TeleportDestination extends Equatable {
  const TeleportDestination({
    required this.poiId,
    required this.point,
    required this.label,
    required this.isCityMarker,
  });

  final String poiId;
  final LatLng point;
  final String label;
  final bool isCityMarker;

  /// Il marker della città; `null` senza marker o senza punto.
  static TeleportDestination? ofCity(City? city) {
    final marker = city?.markerLocation;
    final point = marker?.location;
    if (marker == null || point == null) return null;
    return TeleportDestination(
      poiId: marker.id,
      point: point,
      label: city?.name ?? PoiType.city.label,
      isCityMarker: true,
    );
  }

  /// Un luogo interno; `null` per un marker di città, senza punto o senza un
  /// tipo noto all'app (non avrebbe nome né punto sulla mappa, D-29).
  static TeleportDestination? ofPlace(PointOfInterest poi) {
    final point = poi.location;
    if (point == null || _isCityMarker(poi)) return null;
    if (_placeTypeOf(poi) == null) return null;
    return TeleportDestination(
      poiId: poi.id,
      point: point,
      label: placeLabelOf(poi),
      isCityMarker: false,
    );
  }

  @override
  List<Object?> get props => [poiId, point, label, isCityMarker];
}

/// «Tipo presso città» per un luogo interno (es. «Rovine presso Talmvere»),
/// il nome della città per un marker (D-29).
String placeLabelOf(PointOfInterest poi) {
  final cityName = poi.city?.name;
  if (_isCityMarker(poi)) return cityName ?? PoiType.city.label;
  final type = _placeTypeOf(poi);
  if (type == null) return cityName ?? '';
  if (cityName == null) return type.label;
  return '${type.label} presso $cityName';
}

/// Solo i luoghi interni con un punto, nell'ordine del BE.
List<TeleportDestination> innerPlacesOf(
  List<PointOfInterest> pointsOfInterest,
) => List.unmodifiable(
  pointsOfInterest.map(TeleportDestination.ofPlace).nonNulls,
);

bool _isCityMarker(PointOfInterest poi) =>
    (poi.type ?? const []).contains(PoiType.city);

PoiType? _placeTypeOf(PointOfInterest poi) {
  for (final type in poi.type ?? const <PoiType>[]) {
    if (type != PoiType.city && type != PoiType.all) return type;
  }
  return null;
}
