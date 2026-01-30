import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';

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

        final showableQuests = _getShowableQuests(state.quests);

        return MarkerLayer(
          markers: showableQuests.map((quest) => _buildQuestMarker(quest)).toList(),
        );
      },
    );
  }

  List<Quest> _getShowableQuests(List<Quest> quests) {
    return quests.where((quest) {
      if (quest.infos?.markerLocation == null) return false;

      // Don't show quest markers that overlap with city markers
      return !cities.any(
        (city) => city.markerLocation == quest.infos?.markerLocation,
      );
    }).toList();
  }

  Marker _buildQuestMarker(Quest quest) {
    return Marker(
      key: ValueKey(quest.id),
      point: quest.infos!.markerLocation!.location!,
      child: ValueListenableBuilder<double>(
        valueListenable: zoomNotifier,
        builder: (_, zoom, child) {
          if (zoom <= MapConstants.questVisibleZoom) {
            return const SizedBox.shrink();
          }
          return Transform.scale(
            scale: zoom * 0.4 + 0.1,
            child: child!,
          );
        },
        child: GestureDetector(
          onTap: () => onQuestSelected(quest),
          child: CachedSvg(url: quest.infos!.type!.imagePath),
        ),
      ),
    );
  }
}

