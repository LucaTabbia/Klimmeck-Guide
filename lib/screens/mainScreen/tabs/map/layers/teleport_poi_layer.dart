import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../../../../models/travel/teleport_destination.dart';
import '../../../../../theme/kg_theme.dart';
import '../utils/teleport_drop.dart';
import 'pawn_visuals.dart';

/// Luoghi interni come bersagli del teletrasporto (D-29): un punto per luogo,
/// solo in modalità teletrasporto e da zoom città. Un tocco sul punto mostra i
/// tipi del luogo, un secondo tocco li nasconde (UAT 2026-11-14).
class TeleportPoiLayer extends StatefulWidget {
  const TeleportPoiLayer({
    super.key,
    required this.places,
    required this.zoomNotifier,
  });

  static Key placeKeyFor(String poiId) => ValueKey('map.teleportPlace.$poiId');
  static const Key typesLabelKey = ValueKey('map.teleportPlaceTypes');

  static const double dotSize = 14;
  static const double _tapTarget = 44;
  static const int _typesMaxLines = 3;

  final List<TeleportDestination> places;
  final ValueNotifier<double> zoomNotifier;

  @override
  State<TeleportPoiLayer> createState() => _TeleportPoiLayerState();
}

class _TeleportPoiLayerState extends State<TeleportPoiLayer> {
  String? _shownPoiId;

  @override
  Widget build(BuildContext context) {
    final shown = _shownPlace;
    return MarkerLayer(
      markers: [
        for (final place in widget.places)
          Marker(
            point: place.point,
            width: TeleportPoiLayer._tapTarget,
            height: TeleportPoiLayer._tapTarget,
            child: _visibleAtCityZoom(_buildTappableDot(place)),
          ),
        if (shown != null)
          Marker(
            point: shown.point,
            width: PawnLabel.markerWidth,
            height: PawnLabel.markerHeight,
            alignment: Alignment.topCenter,
            child: _visibleAtCityZoom(
              Align(
                alignment: Alignment.topCenter,
                child: PawnLabel(
                  key: TeleportPoiLayer.typesLabelKey,
                  maxLines: TeleportPoiLayer._typesMaxLines,
                  text: shown.typesLine.isEmpty ? shown.label : shown.typesLine,
                ),
              ),
            ),
          ),
      ],
    );
  }

  TeleportDestination? get _shownPlace {
    for (final place in widget.places) {
      if (place.poiId == _shownPoiId) return place;
    }
    return null;
  }

  Widget _visibleAtCityZoom(Widget child) => ValueListenableBuilder<double>(
    valueListenable: widget.zoomNotifier,
    builder: (_, zoom, visible) =>
        innerPlacesVisibleAt(zoom) ? visible! : const SizedBox.shrink(),
    child: child,
  );

  Widget _buildTappableDot(TeleportDestination place) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(
        () => _shownPoiId = _shownPoiId == place.poiId ? null : place.poiId,
      ),
      child: Center(
        child: SizedBox.square(
          dimension: TeleportPoiLayer.dotSize,
          child: DecoratedBox(
            key: TeleportPoiLayer.placeKeyFor(place.poiId),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: KlimmeckGuideTheme.arcanePurple,
              border: Border.all(color: KlimmeckGuideTheme.parchment, width: 2),
            ),
          ),
        ),
      ),
    );
  }
}
