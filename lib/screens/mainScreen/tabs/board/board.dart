import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/models/city.dart';
import 'package:klimmeck_guide/models/quest/board_policy.dart';
import 'package:klimmeck_guide/models/quest/quest_availability.dart';
import 'package:klimmeck_guide/models/quest/quest_viewer.dart';
import 'package:klimmeck_guide/repository/services/auth/auth_token_service.dart';
import 'package:klimmeck_guide/screens/auth/cubit/auth_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/characterCubit/character_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/questAcceptanceCubit/quest_acceptance_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/questCubit/quest_cubit.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/board/components/sheet.dart';
import 'package:klimmeck_guide/shared/components/popup/quest_info_sheet.dart';
import 'package:klimmeck_guide/shared/components/tear/tear_clipper.dart';
import 'package:klimmeck_guide/shared/components/tear/tearable_paper.dart';

import '../../../../models/quest/quest.dart';

class Board extends StatefulWidget {
  const Board({super.key, required this.cities, this.onQuestAccepted});

  /// Città caricate dal MainScreen: dicono se il personaggio è su un marker (D-11).
  final List<City> cities;

  /// Chiamata solo su QuestAccepted (D-03): il MainScreen passa alla mappa.
  final VoidCallback? onQuestAccepted;

  @override
  State<Board> createState() => _BoardState();
}

class _BoardState extends State<Board> with SingleTickerProviderStateMixin {
  String? _selectedQuestId;

  final GlobalKey<TearablePaperState> _tearKey = GlobalKey<TearablePaperState>();

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

    _animationController.addStatusListener(_onAnimationStatusChanged);

    final character = context.read<CharacterCubit>().state;
    final city = character is CharacterLoaded
        ? currentCityOf(widget.cities, character.character.status?.location)
        : null;
    context.read<QuestCubit>().refreshQuests(cityId: city?.id);
  }

  void _onAnimationStatusChanged(AnimationStatus status) {
    if (status.isDismissed) {
      setState(() {
        _selectedQuestId = null;
      });
    }
  }

  @override
  void dispose() {
    _animationController.removeStatusListener(_onAnimationStatusChanged);
    _animationController.dispose();
    super.dispose();
  }

  Offset _getQuestOffset(Quest quest) {
    return _questOffsets.putIfAbsent(
      quest.id,
      () => Offset(
        (_random.nextDouble() - 0.5) * 30,
        (_random.nextDouble() - 0.5) * 30,
      ),
    );
  }

  double _getQuestRandomizer(Quest quest) {
    return _questRandomizers.putIfAbsent(
      quest.id,
      () => _random.nextDouble() * 20,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final twitchPoints = context.select<AuthCubit, int?>(
      (cubit) => switch (cubit.state) {
        AuthAuthenticated(:final user) => user.twitchPoints,
        _ => null,
      },
    );

    return BlocBuilder<CharacterCubit, CharacterState>(
      builder: (context, characterState) => BlocBuilder<QuestCubit, QuestState>(
        builder: (context, questState) {
          final viewer = _viewerOf(characterState, questState, twitchPoints);
          final listed = viewer == null || questState is! QuestLoaded
              ? const <Quest>[]
              : boardQuestsFor(questState.quests, viewer);
          return _buildBoard(screenHeight, screenWidth, viewer, listed);
        },
      ),
    );
  }

  /// Viewer live (personaggio + saldo + POI della città); null fuori da un marker (D-11).
  QuestViewer? _viewerOf(
    CharacterState characterState,
    QuestState questState,
    int? twitchPoints,
  ) {
    if (characterState is! CharacterLoaded || questState is! QuestLoaded) {
      return null;
    }
    final character = characterState.character;
    final city = currentCityOf(widget.cities, character.status?.location);
    if (city == null) return null;
    return QuestViewer.of(
      character: character,
      twitchPoints: twitchPoints,
      cityPointIds: questState.cityId == city.id
          ? questState.cityPointIds
          : null,
    );
  }

  Quest? _selectedAmong(List<Quest> listed) {
    for (final quest in listed) {
      if (quest.id == _selectedQuestId) return quest;
    }
    return null;
  }

  Widget _buildBoard(
    double screenHeight,
    double screenWidth,
    QuestViewer? viewer,
    List<Quest> listed,
  ) {
    return BlocListener<QuestAcceptanceCubit, QuestAcceptanceState>(
      listenWhen: (previous, current) =>
          current is QuestAccepted || current is QuestAcceptanceFailed,
      listener: _onAcceptanceOutcome,
      child: Stack(
        children: [
          SingleChildScrollView(
            child: Stack(
              children: [
                GestureDetector(
                  onTap: () {
                    if (_selectedQuestId != null) {
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
                  child: _papers(viewer, listed),
                ),
              ],
            ),
          ),
          _buildQuestInfoSheet(screenHeight, viewer, _selectedAmong(listed)),
        ],
      ),
    );
  }

  /// Solo ciò che richiede la Board montata; banner, refresh e reset sono in
  /// QuestAcceptanceOutcomeListener (MainScreen).
  void _onAcceptanceOutcome(BuildContext context, QuestAcceptanceState state) {
    if (state is QuestAccepted) {
      widget.onQuestAccepted?.call();
    } else if (state is QuestAcceptanceFailed) {
      _tearKey.currentState?.recompose();
    }
  }

  Widget _papers(QuestViewer? viewer, List<Quest> listed) {
    if (viewer == null) return const SizedBox.shrink();
    return Wrap(
      spacing: 30,
      runSpacing: 20,
      children: listed.map((quest) {
        return Transform.translate(
          offset: _getQuestOffset(quest),
          child: Sheet(
            key: ValueKey(quest.id),
            quest: quest,
            isTorn: standingOf(quest, viewer).isTorn,
            onTap: _selectQuest,
            randomizer: _getQuestRandomizer(quest),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildQuestInfoSheet(
    double screenHeight,
    QuestViewer? viewer,
    Quest? selected,
  ) {
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
              child: selected != null && viewer != null
                  ? SingleChildScrollView(
                      key: ValueKey('board-sheet-${selected.id}'),
                      clipBehavior: Clip.none,
                      child:
                          BlocSelector<
                            QuestAcceptanceCubit,
                            QuestAcceptanceState,
                            bool
                          >(
                            selector: (state) => state is! QuestAccepting,
                            builder: (context, isIdle) => TearablePaper(
                              key: _tearKey,
                              tearSeed: TearClipper.seedOf(selected.id),
                              canTear: standingOf(selected, viewer).canAccept,
                              isEnabled: isIdle,
                              onTorn: () => _accept(viewer, selected),
                              child: ColoredBox(
                                color: Colors.transparent,
                                child: QuestInfoSheet(
                                  quest: selected,
                                  viewer: viewer,
                                ),
                              ),
                            ),
                          ),
                    )
                  : null,
            ),
          ),
        );
      },
    );
  }

  void _accept(QuestViewer viewer, Quest quest) =>
      context.read<QuestAcceptanceCubit>().accept(
        characterId: viewer.characterId,
        questId: quest.id,
      );

  void _selectQuest(Quest quest) {
    setState(() {
      _selectedQuestId = quest.id;
    });
    _animationController.forward();
  }
}
