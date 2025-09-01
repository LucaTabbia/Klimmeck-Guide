import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:klimmeck_guide/models/enums/quest_type.dart';

import '../../../../../models/quest/quest.dart';

class Sheet extends StatefulWidget {
  const Sheet({super.key, required this.onTap, required this.quest, required this.randomizer});

  final Function(Quest) onTap;
  final double randomizer;
  final Quest quest;

  @override
  State<Sheet> createState() => _SheetState();
}

class _SheetState extends State<Sheet> {
  final List<String> _questImages = [
    "assets/icons/svg/sheets/questSheet1.svg",
    "assets/icons/svg/sheets/questSheet2.svg",
  ];
  final List<String> _questTornImages = [
    "assets/icons/svg/sheets/questTornSheet1.svg",
    "assets/icons/svg/sheets/questTornSheet2.svg",
  ];
  final List<String> _jobImages = [
    "assets/icons/svg/sheets/jobSheet1.svg",
    "assets/icons/svg/sheets/jobSheet2.svg",
  ];
  final List<String> _announcementImages = [
    "assets/icons/svg/sheets/announcementSheet1.svg",
    "assets/icons/svg/sheets/announcementSheet2.svg",
  ];
  final List<String> _crimeImages = [
    "assets/icons/svg/sheets/crimeSheet1.svg",
    "assets/icons/svg/sheets/crimeSheet2.svg",
  ];
  final List<String> _storyImages = [
    "assets/icons/svg/sheets/storySheet1.svg",
    "assets/icons/svg/sheets/storySheet2.svg",
  ];
  final List<String> _storyTornImages = [
    "assets/icons/svg/sheets/storyTornSheet1.svg",
    "assets/icons/svg/sheets/storyTornSheet2.svg",
  ];
  final List<String> _huntImages = [
    "assets/icons/svg/sheets/huntSheet1.svg",
    "assets/icons/svg/sheets/huntSheet2.svg",
  ];
  final List<String> _huntTornImages = [
    "assets/icons/svg/sheets/huntTornSheet1.svg",
    "assets/icons/svg/sheets/huntTornSheet2.svg",
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
          _imagePath = isFull ? _randomFrom(_huntTornImages) : _randomFrom(_huntImages);
          break;

        case QuestType.dungeon || QuestType.aid:
          _imagePath = isFull ? _randomFrom(_questTornImages) : _randomFrom(_questImages);
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
          _imagePath = isFull ? _randomFrom(_storyTornImages) : _randomFrom(_storyImages);
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
        child: SvgPicture.asset(_imagePath),
      ),
    );
  }
}
