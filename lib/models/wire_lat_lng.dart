import 'package:latlong2/latlong.dart';

/// Punto `[a, b]` del filo letto come `LatLng(a, b)`: lo stesso ordine di
/// `PointOfInterest.location`. Unico helper per POI e polilinee (07-CONTEXT
/// D-18, C1): il BE costruisce la rotta con le `location` dei POI come estremi,
/// quindi un solo ordine fa coincidere rotta e marker.
LatLng latLngFromWire(List<dynamic> point) =>
    LatLng((point[0] as num).toDouble(), (point[1] as num).toDouble());

/// `null` per un punto malformato o fuori dai limiti della mappa: un punto
/// sbagliato non deve mai far cadere il personaggio intero.
LatLng? tryLatLngFromWire(Object? point) {
  if (point is! List || point.length < 2) return null;
  final latitude = point[0];
  final longitude = point[1];
  if (latitude is! num || longitude is! num) return null;
  if (latitude.abs() > 90 || longitude.abs() > 180) return null;
  return LatLng(latitude.toDouble(), longitude.toDouble());
}
