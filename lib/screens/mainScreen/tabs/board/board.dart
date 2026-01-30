import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/screens/mainScreen/questCubit/quest_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/board/components/sheet.dart';
import 'package:klimmeck_guide/shared/components/popup/quest_info_sheet.dart';

import '../../../../models/quest/quest.dart';

class Board extends StatefulWidget {
  const Board({super.key});

  @override
  State<Board> createState() => _BoardState();
}

class _BoardState extends State<Board> with SingleTickerProviderStateMixin {
  Quest? _selectedQuest;

  late AnimationController _animationController;

  final Map<String, Offset> _questOffsets = {};
  final Map<String, double> _questRandomizers = {};
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _animationController.addStatusListener((status) {
      if (status.isDismissed) {
        setState(() {
          _selectedQuest = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Offset _getQuestOffset(Quest quest) {
    final key = quest.id ?? quest.hashCode.toString();
    return _questOffsets.putIfAbsent(
      key,
      () => Offset(
        (_random.nextDouble() - 0.5) * 30,
        (_random.nextDouble() - 0.5) * 30,
      ),
    );
  }

  double _getQuestRandomizer(Quest quest) {
    final key = quest.id ?? quest.hashCode.toString();
    return _questRandomizers.putIfAbsent(
      key,
      () => _random.nextDouble() * 20,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Stack(
      children: [
        SingleChildScrollView(
          child: Stack(
            children: [
              GestureDetector(
                onTap: () {
                  if (_selectedQuest != null) {
                    _animationController.reverse();
                  }
                },
                child: SizedBox(
                  width: screenWidth,
                  child: Image.asset(
                    'assets/images/boardBackground.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth / 6.5,
                  vertical: screenHeight / 2.3,
                ),
                child: BlocBuilder<QuestCubit, QuestState>(
                  builder: (context, state) {
                    if (state is QuestLoaded) {
                      return Wrap(
                        spacing: 30,
                        runSpacing: 20,
                        children: state.quests.map((quest) {
                          return Transform.translate(
                            offset: _getQuestOffset(quest),
                            child: Sheet(
                              onTap: _selectQuest,
                              quest: quest,
                              randomizer: _getQuestRandomizer(quest),
                            ),
                          );
                        }).toList(),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
        ),
        _buildQuestInfoSheet(screenHeight),
      ],
    );
  }

  Widget _buildQuestInfoSheet(double screenHeight) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final position = Tween<double>(
          begin: screenHeight,
          end: 0.0,
        ).evaluate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
        );

        return Positioned(
          top: position,
          right: 0,
          child: Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              height: screenHeight,
              width: screenHeight * 1.5 * (315 / 375),
              child: _selectedQuest != null
                  ? SingleChildScrollView(
                      child: QuestInfoSheet(quest: _selectedQuest),
                    )
                  : null,
            ),
          ),
        );
      },
    );
  }

  void _selectQuest(Quest quest) {
    setState(() {
      _selectedQuest = quest;
    });
    _animationController.forward();
  }
}
