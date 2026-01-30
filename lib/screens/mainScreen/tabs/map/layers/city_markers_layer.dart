import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../../../../models/city.dart';
import '../../../../../models/enums/city_size_type.dart';
import '../components/city_marker.dart';
import '../cubit/world_map_cubit.dart';
import '../utils/map_constants.dart';

class CityMarkersLayer extends StatelessWidget {
  const CityMarkersLayer({
    super.key,
    required this.cities,
    required this.zoomNotifier,
  });

  final List<City> cities;
  final ValueNotifier<double> zoomNotifier;

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
                  onTap: () => context
                      .read<WorldMapCubit>()
                      .loadLoreData(city.relatedLore!.id),
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

