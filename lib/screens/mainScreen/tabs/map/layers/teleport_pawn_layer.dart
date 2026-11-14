import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../../models/city.dart';
import '../../../../../models/enums/sex_type.dart';
import '../../../../../models/travel/teleport_destination.dart';
import '../../../../../models/travel/teleport_target.dart';
import '../../../../../shared/components/cached_svg.dart';
import '../utils/map_constants.dart';
import '../utils/teleport_drop.dart';
import 'pawn_dragging.dart';
import 'pawn_visuals.dart';

/// Modalità teletrasporto (10-CONTEXT D-15/D-20, C12): sulla mappa c'è solo la
/// pedina del personaggio scelto, col nome sopra; si trascina come quella del
/// giocatore, ma al rilascio vale il luogo interno vicino, altrimenti la città
/// (D-01, D-29). Il punto è quello letto dal BE (C17).
class TeleportPawnLayer extends StatefulWidget {
  const TeleportPawnLayer({
    super.key,
    required this.target,
    required this.places,
    required this.cities,
    required this.zoomNotifier,
    required this.mapController,
    required this.canDrag,
    required this.onDragUpdate,
    required this.onDrop,
  });

  static const Key pawnKey = ValueKey('map.teleportPawn');
  static const Key nameLabelKey = ValueKey('map.teleportNameLabel');

  final TeleportTarget target;
  final List<TeleportDestination> places;
  final List<City> cities;
  final ValueNotifier<double> zoomNotifier;
  final MapController mapController;
  final bool canDrag;
  final void Function(LatLng newLocation) onDragUpdate;
  final void Function(TeleportDestination? destination) onDrop;

  @override
  State<TeleportPawnLayer> createState() => _TeleportPawnLayerState();
}

class _TeleportPawnLayerState extends State<TeleportPawnLayer>
    with PawnDragging<TeleportPawnLayer> {
  @override
  MapController get pawnMapController => widget.mapController;

  @override
  List<City> get dropCities => widget.cities;

  @override
  void onPawnDragUpdate(LatLng point) => widget.onDragUpdate(point);

  @override
  void resolvePawnDrop(LatLng releasePoint) => widget.onDrop(
    teleportDropTarget(
      releasePoint: releasePoint,
      places: widget.places,
      cities: widget.cities,
      toScreen: pawnMapController.camera.latLngToScreenOffset,
      zoom: pawnMapController.camera.zoom,
    ),
  );

  /// Raggiunto solo senza punto di rilascio.
  @override
  void onPawnDragEnd(LatLng? _, City? _) => widget.onDrop(null);

  @override
  Widget build(BuildContext context) {
    final point = dragPoint ?? widget.target.location.location!;
    return MarkerLayer(
      markers: [
        Marker(
          point: point,
          child: ValueListenableBuilder<double>(
            valueListenable: widget.zoomNotifier,
            builder: (_, zoom, child) =>
                Transform.scale(scale: pawnScaleForZoom(zoom), child: child),
            child: _buildDraggablePawn(widget.target.sex.pawnPath),
          ),
        ),
        Marker(
          point: point,
          width: PawnLabel.markerWidth,
          height: PawnLabel.markerHeight,
          alignment: Alignment.topCenter,
          child: Align(
            alignment: Alignment.topCenter,
            child: PawnLabel(
              key: TeleportPawnLayer.nameLabelKey,
              text: widget.target.label,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDraggablePawn(String pawnPath) {
    return Draggable(
      maxSimultaneousDrags: widget.canDrag ? null : 0,
      feedback: SizedBox.square(
        dimension: MapConstants.characterMarkerSize,
        child: CachedSvg(url: pawnPath),
      ),
      childWhenDragging: Opacity(opacity: 0, child: CachedSvg(url: pawnPath)),
      onDragUpdate: handlePawnDragUpdate,
      onDragEnd: (_) => handlePawnDragEnd(),
      child: KeyedSubtree(
        key: TeleportPawnLayer.pawnKey,
        child: CachedSvg(
          height: MapConstants.characterMarkerSize,
          width: MapConstants.characterMarkerSize,
          url: pawnPath,
        ),
      ),
    );
  }
}
