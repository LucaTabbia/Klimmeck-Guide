import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../../../../models/city.dart';
import '../../../../../models/enums/city_size_type.dart';
import '../components/city_marker.dart';
import '../utils/map_constants.dart';

class CityMarkersLayer extends StatelessWidget {
  const CityMarkersLayer({
    super.key,
    required this.cities,
    required this.zoomNotifier,
    this.onCityTap,
  });

  final List<City> cities;
  final ValueNotifier<double> zoomNotifier;

  /// Null in modalità teletrasporto: le città restano bersagli, senza lore (10-CONTEXT C14).
  final void Function(City city)? onCityTap;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: zoomNotifier,
      builder: (context, zoom, _) {
        final visibleCities = _getVisibleCities(zoom);

        return MarkerLayer(
          markers: visibleCities.map((city) {
            return Marker(
              key: ValueKey(city.id),
              point: city.markerLocation!.location!,
              child: Transform.scale(
                scale: _calculateMarkerScale(zoom, city.type!.size),
                child: CityMarker(
                  city: city,
                  onTap: onCityTap == null ? null : () => onCityTap!(city),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  List<City> _getVisibleCities(double zoom) {
    return cities.where((city) {
      switch (city.type?.cityClass) {
        case CitySizeType.capital:
          return zoom >= MapConstants.capitalVisibleZoom;
        case CitySizeType.city:
          return zoom >= MapConstants.cityVisibleZoom;
        case CitySizeType.village:
          return zoom >= MapConstants.villageVisibleZoom;
        default:
          return false;
      }
    }).toList();
  }

  double _calculateMarkerScale(double zoom, int citySize) {
    return (zoom * 0.2 + 0.1) * 0.08 * citySize;
  }
}

