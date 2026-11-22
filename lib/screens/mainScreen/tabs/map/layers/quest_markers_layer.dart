import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../../models/city.dart';
import '../../../../../models/quest/quest.dart';
import '../../../../../shared/components/cached_svg.dart';
import '../../../questCubit/quest_cubit.dart';
import '../utils/map_constants.dart';

class QuestMarkersLayer extends StatelessWidget {
  const QuestMarkersLayer({
    super.key,
    required this.cities,
    required this.zoomNotifier,
    required this.onQuestSelected,
  });

  final List<City> cities;
  final ValueNotifier<double> zoomNotifier;
  final void Function(Quest) onQuestSelected;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<QuestCubit, QuestState>(
      builder: (context, state) {
        if (state is! QuestLoaded) {
          return const SizedBox.shrink();
        }

        return MarkerLayer(
          markers: [
            for (final quest in state.quests)
              if (_markerPointOf(quest) case final point?)
                _buildQuestMarker(quest, point),
          ],
        );
      },
    );
  }

  /// Punto del marker: nessuno per una quest senza luogo (le story), con un
  /// luogo senza coordinate o sovrapposta al marker di una città.
  LatLng? _markerPointOf(Quest quest) {
    final place = quest.infos?.markerLocation;
    if (place == null) return null;
    if (cities.any((city) => city.markerLocation == place)) return null;
    return place.location;
  }

  Marker _buildQuestMarker(Quest quest, LatLng point) {
    return Marker(
      key: ValueKey(quest.id),
      point: point,
      child: ValueListenableBuilder<double>(
        valueListenable: zoomNotifier,
        builder: (_, zoom, child) {
          if (zoom <= MapConstants.questVisibleZoom) {
            return const SizedBox.shrink();
          }
          return Transform.scale(scale: zoom * 0.4 + 0.1, child: child!);
        },
        child: GestureDetector(
          onTap: () => onQuestSelected(quest),
          child: CachedSvg(url: quest.infos!.type!.imagePath),
        ),
      ),
    );
  }
}
