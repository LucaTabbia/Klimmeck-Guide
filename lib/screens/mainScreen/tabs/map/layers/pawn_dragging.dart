import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../../models/city.dart';
import '../utils/map_utils.dart';

/// Trascinamento della pedina a livello di layer (Phase 7 D-01, Pitfall 7): il
/// punto si converte col RenderBox del layer, che copre tutta la mappa; al
/// rilascio vale `MapUtils.dropTargetCity`. Usato dalla pedina del giocatore e
/// da quella del teletrasporto (10-CONTEXT D-15).
mixin PawnDragging<T extends StatefulWidget> on State<T> {
  LatLng? _dragPoint;

  /// Punto sotto il dito, valorizzato solo durante il trascinamento.
  LatLng? get dragPoint => _dragPoint;

  MapController get pawnMapController;

  List<City> get dropCities;

  void onPawnDragUpdate(LatLng point);

  void onPawnDragEnd(LatLng? finalLocation, City? targetCity);

  void handlePawnDragUpdate(DragUpdateDetails details) {
    final renderObject = context.findRenderObject();
    if (!mounted || renderObject is! RenderBox) return;
    if (!renderObject.hasSize || !renderObject.attached) return;

    final localOffset = renderObject.globalToLocal(details.globalPosition);
    final point = pawnMapController.camera.screenOffsetToLatLng(localOffset);
    setState(() => _dragPoint = point);
    onPawnDragUpdate(point);
  }

  void handlePawnDragEnd() {
    final releasePoint = _dragPoint;
    setState(() => _dragPoint = null);
    if (releasePoint == null) {
      onPawnDragEnd(null, null);
      return;
    }

    final targetCity = MapUtils.dropTargetCity(releasePoint, dropCities);
    onPawnDragEnd(targetCity?.markerLocation?.location, targetCity);
  }
}
