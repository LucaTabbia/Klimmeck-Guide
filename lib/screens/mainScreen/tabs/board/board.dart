import 'dart:math';

import 'package:flutter/material.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/board/components/quest_info_sheet.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/board/components/sheet.dart';

import '../../../../models/quest/quest.dart';

class Board extends StatefulWidget {
  const Board({super.key, required this.quests});

  final List<Quest> quests;

  @override
  State<Board> createState() => _BoardState();
}

class _BoardState extends State<Board> with SingleTickerProviderStateMixin {
  Quest? _selectedQuest;

  late AnimationController _animationController;
  late Animation<double> _positionAnimation;
  late final Map<Quest, Offset> _questOffsets;
  late final Map<Quest, double> _questRandomizers;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: Duration(milliseconds: 300));

    _positionAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeIn));

    _animationController.addStatusListener((status) {
      if (status.isDismissed) {
        setState(() {
          _selectedQuest = null;
        });
      }
    });
    final rnd = Random();
    _questOffsets = {
      for (var quest in widget.quests)
        quest: Offset((rnd.nextDouble() - 0.5) * 30, (rnd.nextDouble() - 0.5) * 30),
    };
    _questRandomizers = {for (var quest in widget.quests) quest: rnd.nextDouble() * 20};
  }

  @override
  Widget build(BuildContext context) {
    setState(() {
      _positionAnimation = Tween<double>(
        begin: MediaQuery.of(context).size.height,
        end: 0.0,
      ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeIn));
    });

    return Stack(
      children: [
        SingleChildScrollView(
          child: Stack(
            children: [
              GestureDetector(
                onTap: () => {
                  if (_selectedQuest != null) {_animationController.reverse()},
                },
                child: SizedBox(
                  width: MediaQuery.of(context).size.width,
                  child: Image.asset('assets/images/boardBackground.png', fit: BoxFit.cover),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width / 6.5,
                  vertical: MediaQuery.of(context).size.height / 2.3,
                ),
                child: Wrap(
                  spacing: 30,
                  runSpacing: 20,
                  children: widget.quests.map((quest) {
                    return Transform.translate(
                      offset: _questOffsets[quest]!,
                      child: Sheet(
                        onTap: selectQuest,
                        quest: quest,
                        randomizer: _questRandomizers[quest]!,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Positioned(
              top: _positionAnimation.value,
              right: 0,
              child: Align(
                alignment: Alignment.centerRight,
                child: SizedBox(
                  height: MediaQuery.of(context).size.height,
                  width: MediaQuery.of(context).size.height * 1.3 * (315 / 375),
                  child: _selectedQuest != null
                      ? SingleChildScrollView(child: QuestInfoSheet(quest: _selectedQuest))
                      : null,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  void selectQuest(Quest quest) {
    setState(() {
      _selectedQuest = quest;
    });
    _animationController.forward();
  }
}
