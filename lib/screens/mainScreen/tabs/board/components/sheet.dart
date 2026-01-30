import 'dart:math';

import 'package:flutter/material.dart';
import 'package:klimmeck_guide/config/cloudinary_assets.dart';
import 'package:klimmeck_guide/models/enums/quest_type.dart';
import 'package:klimmeck_guide/shared/components/cached_svg.dart';

import '../../../../../models/quest/quest.dart';

class Sheet extends StatefulWidget {
  const Sheet({
    super.key,
    required this.onTap,
    required this.quest,
    required this.randomizer,
  });

  final Function(Quest) onTap;
  final double randomizer;
  final Quest quest;

  @override
  State<Sheet> createState() => _SheetState();
}

class _SheetState extends State<Sheet> {
  final List<String> _questImages = [
    CloudinaryAssets.url(CloudinaryAssets.questSheet2),
    CloudinaryAssets.url(CloudinaryAssets.questSheet1),
  ];
  final List<String> _questTornImages = [
    CloudinaryAssets.url(CloudinaryAssets.questSheetTorn1),
    CloudinaryAssets.url(CloudinaryAssets.questSheetTorn2),
  ];
  final List<String> _jobImages = [
    CloudinaryAssets.url(CloudinaryAssets.jobSheet1),
    CloudinaryAssets.url(CloudinaryAssets.jobSheet2),
  ];
  final List<String> _announcementImages = [
    CloudinaryAssets.url(CloudinaryAssets.announcementSheet1),
    CloudinaryAssets.url(CloudinaryAssets.announcementSheet2),
  ];
  final List<String> _crimeImages = [
    CloudinaryAssets.url(CloudinaryAssets.crimeSheet1),
    CloudinaryAssets.url(CloudinaryAssets.crimeSheet2),
  ];
  final List<String> _storyImages = [
    CloudinaryAssets.url(CloudinaryAssets.storySheet1),
    CloudinaryAssets.url(CloudinaryAssets.storySheet2),
  ];
  final List<String> _storyTornImages = [
    CloudinaryAssets.url(CloudinaryAssets.storyTornSheet2),
    CloudinaryAssets.url(CloudinaryAssets.storyTornSheet1),
  ];
  final List<String> _huntImages = [
    CloudinaryAssets.url(CloudinaryAssets.huntSheet1),
    CloudinaryAssets.url(CloudinaryAssets.huntSheet2),
  ];
  final List<String> _huntTornImages = [
    CloudinaryAssets.url(CloudinaryAssets.huntTornSheet1),
    CloudinaryAssets.url(CloudinaryAssets.huntTornSheet2),
  ];

  late String _imagePath;

  final Random random = Random();

  String _randomFrom(List<String> images) {
    return images[random.nextInt(images.length)];
  }

  @override
  void initState() {
    super.initState();

    final isFull =
        widget.quest.registeredAdventurers?.length ==
        widget.quest.requirements?.requiredAdventurers;

    if (widget.quest.infos?.type != null) {
      switch (widget.quest.infos!.type!) {
        case QuestType.boss || QuestType.enemy:
          _imagePath = isFull
              ? _randomFrom(_huntTornImages)
              : _randomFrom(_huntImages);
          break;

        case QuestType.dungeon || QuestType.aid:
          _imagePath = isFull
              ? _randomFrom(_questTornImages)
              : _randomFrom(_questImages);
          break;

        case QuestType.crime:
          _imagePath = _randomFrom(_crimeImages);
          break;

        case QuestType.guard || QuestType.hunt || QuestType.job:
          _imagePath = _randomFrom(_jobImages);
          break;

        case QuestType.heal || QuestType.study:
          _imagePath = _randomFrom(_announcementImages);
          break;

        case QuestType.story:
          _imagePath = _randomFrom(_storyImages);
          break;

        case QuestType.worldMission:
          _imagePath = isFull
              ? _randomFrom(_storyTornImages)
              : _randomFrom(_storyImages);
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => widget.onTap(widget.quest),
      child: SizedBox(
        width: widget.randomizer + 150,
        height: widget.randomizer + 150,
        child: CachedSvg(url: _imagePath),
      ),
    );
  }
}
