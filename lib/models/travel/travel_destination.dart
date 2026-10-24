import '../city.dart';
import '../point_of_interest.dart';

/// D-01/D-02: la città su cui è stata rilasciata la pedina è la meta, tranne
/// quella in cui il personaggio si trova già (ritorno silenzioso, nessuna
/// anteprima). Una città senza marker non è una meta.
City? travelDestinationFor({
  required City? target,
  required PointOfInterest? location,
}) {
  final marker = target?.markerLocation;
  if (target == null || marker == null) return null;
  if (marker.id == location?.id) return null;
  return target;
}
