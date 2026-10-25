import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:klimmeck_guide/config/cloudinary_assets.dart';
import 'package:klimmeck_guide/shared/components/cached_svg.dart';
import 'package:klimmeck_guide/shared/components/cards/loot_item_card.dart';
import 'package:klimmeck_guide/shared/components/coins_display.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';
import 'package:klimmeck_guide/utils/utils.dart';

import '../../../models/quest/quest.dart';
import '../../../models/quest/quest_sheet_details.dart';
import '../../../models/quest/quest_viewer.dart';
import '../cards/equipment_item_card.dart';

class QuestInfoSheet extends StatelessWidget {
  const QuestInfoSheet({
    super.key,
    required this.quest,
    this.viewer,
    this.stateLabel,
    this.onAbandon,
  });

  final Quest? quest;

  /// Chi guarda (board): abilita titolo evidenziato, motivo del blocco, saldo.
  /// Null = sola lettura (mappa).
  final QuestViewer? viewer;

  /// Etichetta di stato della corsia (mappa, D-15).
  final String? stateLabel;

  /// Solo dalla mappa, mentre la corsia aspetta il gruppo (BE 09-19).
  final VoidCallback? onAbandon;

  static const Key combatFamilyKey = ValueKey('questSheet.family.combat');
  static const Key narrativeFamilyKey = ValueKey('questSheet.family.narrative');
  static const Key serviceFamilyKey = ValueKey('questSheet.family.service');
  static const Key costLineKey = ValueKey('questSheet.costLine');
  static const Key blockedReasonKey = ValueKey('questSheet.blockedReason');
  static const Key stateLabelKey = ValueKey('questSheet.stateLabel');
  static const Key abandonKey = ValueKey('questSheet.abandon');
  static const String abandonLabel = 'Abbandona il gruppo';
  static const Size _minTapTarget = Size(44, 44);

  static const double _aspectRatio = 315 / 375;
  static const double _heightMultiplier = 1.5;
  static const EdgeInsets _contentPadding = EdgeInsets.only(
    top: 0.167,
    left: 0.111,
    right: 0.111,
    bottom: 0.13,
  );

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final sheetHeight = screenHeight * _heightMultiplier;
    final sheetWidth = sheetHeight * _aspectRatio;

    return Stack(
      alignment: Alignment.topCenter,
      children: [
        CachedSvg(
          url: CloudinaryAssets.url(CloudinaryAssets.emptySheet),
          height: sheetHeight,
          width: sheetWidth,
        ),
        if (quest != null) _buildContent(sheetWidth, sheetHeight),
      ],
    );
  }

  Widget _buildContent(double sheetWidth, double sheetHeight) {
    return SizedBox(
      width: sheetWidth,
      height: sheetHeight,
      child: Padding(
        padding: EdgeInsets.only(
          top: sheetHeight * _contentPadding.top,
          left: sheetWidth * _contentPadding.left,
          right: sheetWidth * _contentPadding.right,
          bottom: sheetHeight * _contentPadding.bottom,
        ),
        child: Column(
          children: [
            Expanded(flex: 3, child: _buildQuestInfo()),
            if (quest!.prizes != null)
              Expanded(flex: 2, child: _buildRewards()),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestInfo() {
    final details = QuestSheetDetails.of(quest!, viewer: viewer);
    final theme = KlimmeckGuideTheme.instance;
    return Column(
      children: [
        Flexible(
          child: AutoSizeText(
            quest!.infos?.title ?? '',
            maxFontSize: 24,
            minFontSize: 10,
            maxLines: 2,
            textAlign: TextAlign.center,
            style: theme.headlineLarge,
          ),
        ),
        Expanded(
          flex: 4,
          child: switch (details.family) {
            QuestSheetFamily.combat => _combatBody(details),
            QuestSheetFamily.narrative => _narrativeBody(details),
            QuestSheetFamily.service => _serviceBody(details),
          },
        ),
        if (details.blockedReason != null)
          Text(
            details.blockedReason!,
            key: blockedReasonKey,
            style: theme.bodyLarge.copyWith(color: KlimmeckGuideTheme.bloodRed),
          ),
        if (stateLabel != null)
          Text(stateLabel!, key: stateLabelKey, style: theme.specialText),
        if (onAbandon != null) _abandonAction(theme),
      ],
    );
  }

  Widget _abandonAction(KlimmeckGuideTheme theme) => Semantics(
    label: abandonLabel,
    button: true,
    child: TextButton(
      key: abandonKey,
      onPressed: onAbandon,
      style: TextButton.styleFrom(
        minimumSize: _minTapTarget,
        foregroundColor: KlimmeckGuideTheme.bloodRed,
      ),
      child: Text(
        abandonLabel,
        style: theme.bodyLarge.copyWith(color: KlimmeckGuideTheme.bloodRed),
      ),
    ),
  );

  Widget _combatBody(QuestSheetDetails details) {
    final enemy = quest!.infos?.enemy;
    return Row(
      key: combatFamilyKey,
      children: [
        if (enemy != null)
          Expanded(
            child: Column(
              children: [
                if (enemy.imagePath != null)
                  Expanded(
                    child: Image.asset(
                      enemy.imagePath!,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
                    ),
                  ),
                AutoSizeText(
                  enemy.name ?? '',
                  maxFontSize: 12,
                  minFontSize: 8,
                  textAlign: TextAlign.center,
                  style: KlimmeckGuideTheme.instance.bodyLarge,
                ),
              ],
            ),
          ),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ..._timeLine(),
                ..._titleLine(details),
                ..._slotLines(details),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _narrativeBody(QuestSheetDetails details) {
    return Column(
      key: narrativeFamilyKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (details.loreParagraphs.isNotEmpty)
          Expanded(
            child: SingleChildScrollView(
              child: Text(
                details.loreParagraphs.join('\n\n'),
                style: KlimmeckGuideTheme.instance.bodyLarge,
              ),
            ),
          ),
        ..._costLine(details),
        ..._titleLine(details),
        ..._slotLines(details),
      ],
    );
  }

  Widget _serviceBody(QuestSheetDetails details) {
    final theme = KlimmeckGuideTheme.instance;
    return SingleChildScrollView(
      key: serviceFamilyKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ..._timeLine(),
          ..._titleLine(details),
          if (details.recommendedLootLines.isNotEmpty) ...[
            Text('Consigliati', style: theme.specialText),
            for (final line in details.recommendedLootLines)
              Text(line, style: theme.bodyLarge),
          ],
          ..._slotLines(details),
        ],
      ),
    );
  }

  List<Widget> _timeLine() {
    final millis = quest!.infos?.timeToComplete;
    if (millis == null) return const [];
    return [
      Text(
        'Tempo richiesto: ${getStringToShowFromDuration(Duration(milliseconds: millis))}',
        style: KlimmeckGuideTheme.instance.bodyLarge,
      ),
    ];
  }

  List<Widget> _titleLine(QuestSheetDetails details) {
    final text = details.requiredTitleText;
    if (text == null) return const [];
    return [
      Text(
        text,
        style: KlimmeckGuideTheme.instance.bodyLarge.copyWith(
          color: details.isTitleIneligible ? KlimmeckGuideTheme.bloodRed : null,
        ),
      ),
    ];
  }

  List<Widget> _costLine(QuestSheetDetails details) {
    final cost = details.costLine;
    if (cost == null) return const [];
    return [
      Text(
        cost.text,
        key: costLineKey,
        style: KlimmeckGuideTheme.instance.bodyLarge.copyWith(
          color: cost.isInsufficient ? KlimmeckGuideTheme.bloodRed : null,
        ),
      ),
    ];
  }

  List<Widget> _slotLines(QuestSheetDetails details) => [
    for (final line in details.slotLines)
      Text(
        line.text,
        style: line.isViewerRank
            ? KlimmeckGuideTheme.instance.specialText
            : KlimmeckGuideTheme.instance.bodyLarge,
      ),
  ];

  Widget _buildRewards() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 30,
              child: AutoSizeText(
                "Ricompense:",
                maxFontSize: 20,
                minFontSize: 10,
                textAlign: TextAlign.left,
                style: KlimmeckGuideTheme.instance.specialText,
              ),
            ),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (quest!.prizes?.prizeCoins != null)
                    CoinsDisplay(
                      coins: quest!.prizes!.prizeCoins!,
                      height: constraints.maxHeight - 30,
                      width: constraints.maxWidth * 0.5,
                    ),
                  if (quest!.prizes!.prizeItem != null)
                    Flexible(
                      child: quest!.prizes!.prizeItem!.isEquipment
                          ? EquipmentItemCard(
                              isSelected: false,
                              size: constraints.maxHeight - 30,
                              equipmentItem:
                                  quest!.prizes!.prizeItem!.asEquipment!,
                            )
                          : LootItemCard(
                              lootItem: quest!.prizes!.prizeItem!.asLoot!,
                              size: constraints.maxHeight - 30,
                            ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
