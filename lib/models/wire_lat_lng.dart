import 'package:latlong2/latlong.dart';

/// Punto `[a, b]` del filo letto come `LatLng(a, b)`: lo stesso ordine di
/// `PointOfInterest.location`. Unico helper per POI e polilinee (07-CONTEXT
/// D-18, C1): il BE costruisce la rotta con le `location` dei POI come estremi,
/// quindi un solo ordine fa coincidere rotta e marker.
///
/// Rigoroso: lancia su un punto malformato. È il contratto di
/// `PointOfInterest.location`, ancora di marker e posizione del personaggio:
/// un POI rotto è un difetto di dati che deve emergere, non sparire.
LatLng latLngFromWire(List<dynamic> point) =>
    LatLng((point[0] as num).toDouble(), (point[1] as num).toDouble());

/// `null` per un punto malformato o fuori dai limiti della mappa: un punto
/// sbagliato non deve mai far cadere il personaggio intero. Tollerante, solo
/// per i nodi intermedi delle polilinee (`TravelPath`): stesso ordine di
/// [latLngFromWire], ma un nodo scartato accorcia la rotta invece di lanciare.
LatLng? tryLatLngFromWire(Object? point) {
  if (point is! List || point.length < 2) return null;
  final latitude = point[0];
  final longitude = point[1];
  if (latitude is! num || longitude is! num) return null;
  if (latitude.abs() > 90 || longitude.abs() > 180) return null;
  return LatLng(latitude.toDouble(), longitude.toDouble());
}
