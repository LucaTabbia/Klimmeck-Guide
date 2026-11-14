import 'package:flutter/widgets.dart';
import 'package:latlong2/latlong.dart';

import '../../../../../models/city.dart';
import '../../../../../models/travel/teleport_destination.dart';
import 'map_utils.dart';

/// Raggio in pixel di schermo entro cui il rilascio cade su un luogo interno (D-29).
const double teleportPlaceDropRadius = 32;

/// Regola di rilascio della sola pedina del teletrasporto (D-01, D-29): il luogo interno più vicino
/// entro [radius] pixel, altrimenti la città della regola del viaggio (Phase 7 D-01). Pura.
TeleportDestination? teleportDropTarget({
  required LatLng releasePoint,
  required List<TeleportDestination> places,
  required List<City> cities,
  required Offset Function(LatLng point) toScreen,
  double radius = teleportPlaceDropRadius,
}) {
  final releaseOffset = toScreen(releasePoint);
  TeleportDestination? nearestPlace;
  var nearestDistance = radius;
  for (final place in places) {
    final distance = (toScreen(place.point) - releaseOffset).distance;
    if (distance > nearestDistance) continue;
    nearestPlace = place;
    nearestDistance = distance;
  }
  return nearestPlace ??
      TeleportDestination.ofCity(MapUtils.dropTargetCity(releasePoint, cities));
}
