import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../../../../models/travel/teleport_destination.dart';
import '../../../../../theme/kg_theme.dart';
import '../utils/map_constants.dart';

/// Luoghi interni come bersagli del teletrasporto (D-29): un punto per luogo,
/// solo in modalità teletrasporto e da zoom città; nessun tap, il chip dice
/// cosa sono.
class TeleportPoiLayer extends StatelessWidget {
  const TeleportPoiLayer({
    super.key,
    required this.places,
    required this.zoomNotifier,
  });

  static Key placeKeyFor(String poiId) => ValueKey('map.teleportPlace.$poiId');

  static const double dotSize = 14;

  final List<TeleportDestination> places;
  final ValueNotifier<double> zoomNotifier;

  @override
  Widget build(BuildContext context) {
    return MarkerLayer(
      markers: [
        for (final place in places)
          Marker(
            point: place.point,
            width: dotSize,
            height: dotSize,
            child: ValueListenableBuilder<double>(
              valueListenable: zoomNotifier,
              builder: (_, zoom, dot) => zoom < MapConstants.cityVisibleZoom
                  ? const SizedBox.shrink()
                  : dot!,
              child: _buildDot(place),
            ),
          ),
      ],
    );
  }

  Widget _buildDot(TeleportDestination place) {
    return DecoratedBox(
      key: placeKeyFor(place.poiId),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: KlimmeckGuideTheme.arcanePurple,
        border: Border.all(color: KlimmeckGuideTheme.parchment, width: 2),
      ),
    );
  }
}
