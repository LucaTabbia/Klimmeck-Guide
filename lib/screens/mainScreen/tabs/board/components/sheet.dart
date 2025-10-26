import 'dart:math';

import 'package:flutter/material.dart';
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
    "https://res.cloudinary.com/dzuhywp53/image/upload/v1757660778/questSheet2_ekuuzv.svg",
    "https://res.cloudinary.com/dzuhywp53/image/upload/v1757660768/questSheet1_c0hswz.svg",
  ];
  final List<String> _questTornImages = [
    "https://res.cloudinary.com/dzuhywp53/image/upload/v1757660760/questSheetTorn1_ds3oyp.svg",
    "https://res.cloudinary.com/dzuhywp53/image/upload/v1757660756/questSheetTorn2_guqkvh.svg",
  ];
  final List<String> _jobImages = [
    "https://res.cloudinary.com/dzuhywp53/image/upload/v1757660765/jobSheet1_osfobz.svg",
    "https://res.cloudinary.com/dzuhywp53/image/upload/v1757660773/jobSheet2_dgkg6x.svg",
  ];
  final List<String> _announcementImages = [
    "https://res.cloudinary.com/dzuhywp53/image/upload/v1757660770/announcementSheet1_bmh8f2.svg",
    "https://res.cloudinary.com/dzuhywp53/image/upload/v1757660776/announcementSheet2_tpub5j.svg",
  ];
  final List<String> _crimeImages = [
    "https://res.cloudinary.com/dzuhywp53/image/upload/v1757660763/crimeSheet1_yhl3tp.svg",
    "https://res.cloudinary.com/dzuhywp53/image/upload/v1757660761/crimeSheet2_q0aysa.svg",
  ];
  final List<String> _storyImages = [
    "https://res.cloudinary.com/dzuhywp53/image/upload/v1757660783/storySheet1_evrqbp.svg",
    "https://res.cloudinary.com/dzuhywp53/image/upload/v1757660774/storySheet2_jsq0nv.svg",
  ];
  final List<String> _storyTornImages = [
    "https://res.cloudinary.com/dzuhywp53/image/upload/v1757660754/storyTornSheet2_bhl8um.svg",
    "https://res.cloudinary.com/dzuhywp53/image/upload/v1757660766/storyTornSheet1_sxqcw0.svg",
  ];
  final List<String> _huntImages = [
    "https://res.cloudinary.com/dzuhywp53/image/upload/v1757660781/huntSheet1_ufnh7p.svg",
    "https://res.cloudinary.com/dzuhywp53/image/upload/v1757660779/huntSheet2_to0gfr.svg",
  ];
  final List<String> _huntTornImages = [
    "https://res.cloudinary.com/dzuhywp53/image/upload/v1757660753/huntTornSheet1_j8irp4.svg",
    "https://res.cloudinary.com/dzuhywp53/image/upload/v1757660749/huntTornSheet2_kqqouj.svg",
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
