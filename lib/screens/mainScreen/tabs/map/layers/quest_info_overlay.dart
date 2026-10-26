import 'package:flutter/material.dart';

import '../../../../../models/quest/quest.dart';
import '../../../../../shared/components/popup/quest_info_sheet.dart';

class QuestInfoOverlay extends StatelessWidget {
  const QuestInfoOverlay({
    super.key,
    required this.animationController,
    required this.selectedQuest,
    this.stateLabel,
    this.onAbandon,
  });

  final AnimationController animationController;
  final Quest? selectedQuest;

  /// Stato della corsia quando il foglio si apre dalla mappa (D-07/D-15).
  final String? stateLabel;

  /// Abbandono del gruppo in attesa, solo dal foglio della corsia (BE 09-19).
  final VoidCallback? onAbandon;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return AnimatedBuilder(
      animation: animationController,
      builder: (context, child) {
        final positionValue = Tween<double>(begin: screenHeight, end: 0.0)
            .evaluate(
              CurvedAnimation(
                parent: animationController,
                curve: Curves.easeIn,
              ),
            );

        return Positioned(
          top: positionValue,
          right: 0,
          child: Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              height: screenHeight,
              width: screenHeight * 1.5 * (315 / 375),
              child: selectedQuest != null
                  ? SingleChildScrollView(
                      child: QuestInfoSheet(
                        quest: selectedQuest,
                        stateLabel: stateLabel,
                        onAbandon: onAbandon,
                      ),
                    )
                  : null,
            ),
          ),
        );
      },
    );
  }
}
