import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/cloudinary_assets.dart';
import '../../../../../models/pending_quest.dart';
import '../../../../../models/quest/quest.dart';
import '../../../../../models/quest/quest_lane.dart';
import '../../../../../models/quest/quest_paper_asset.dart';
import '../../../../../models/quest/quest_state_label.dart';
import '../../../../../shared/components/cached_svg.dart';
import '../../../../../theme/kg_theme.dart';
import '../../../characterCubit/character_cubit.dart';
import '../../../questCubit/quest_cubit.dart';

/// Foglio intero della quest standard accettata, sulla mappa finché la corsia è
/// piena (D-07); story/worldMission non compaiono mai (D-08). Nessun countdown:
/// solo l'etichetta di stato guidata dal server (D-15).
class QuestPaperLayer extends StatelessWidget {
  const QuestPaperLayer({super.key, required this.onOpen});

  final void Function(Quest quest, String stateLabel) onOpen;

  static const Key paperKey = ValueKey('map.questPaper');
  static const double _paperSize = 110;
  static const double _tilt = -0.08;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CharacterCubit, CharacterState>(
      builder: (context, characterState) {
        return BlocBuilder<QuestCubit, QuestState>(
          builder: (context, questState) {
            final lane = characterState is CharacterLoaded
                ? characterState.character.quests?.pendingQuest
                : null;
            final quest = _laneQuest(lane, questState);
            final type = quest?.infos?.type;
            if (lane == null ||
                quest == null ||
                type == null ||
                laneOf(type) != QuestLane.standard) {
              return const SizedBox.shrink();
            }
            final label = questStateLabel(lane, type);
            return Align(
              alignment: Alignment.topLeft,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(KlimmeckGuideTheme.spacingMd),
                  child: GestureDetector(
                    key: paperKey,
                    onTap: () => onOpen(quest, label),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Transform.rotate(
                          angle: _tilt,
                          child: SizedBox.square(
                            dimension: _paperSize,
                            child: CachedSvg(
                              url: CloudinaryAssets.url(
                                questPaperAssetId(quest, isTorn: false),
                              ),
                            ),
                          ),
                        ),
                        Text(
                          label,
                          style: KlimmeckGuideTheme.instance.bodyLarge.copyWith(
                            color: KlimmeckGuideTheme.parchment,
                            shadows: KlimmeckGuideTheme.bordersForText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Quest? _laneQuest(PendingQuest? lane, QuestState state) {
    final id = lane?.quest?.id;
    if (id == null || state is! QuestLoaded) return null;
    for (final quest in state.quests) {
      if (quest.id == id) return quest;
    }
    return null;
  }
}
