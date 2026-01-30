import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:klimmeck_guide/config/cloudinary_assets.dart';
import 'package:klimmeck_guide/shared/components/cached_svg.dart';
import 'package:klimmeck_guide/shared/components/cards/loot_item_card.dart';
import 'package:klimmeck_guide/shared/components/coins_display.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';
import 'package:klimmeck_guide/utils/utils.dart';

import '../../../models/quest/quest.dart';
import '../cards/equipment_item_card.dart';

class QuestInfoSheet extends StatefulWidget {
  const QuestInfoSheet({super.key, required this.quest});

  final Quest? quest;

  @override
  State<QuestInfoSheet> createState() => _QuestInfoSheetState();
}

class _QuestInfoSheetState extends State<QuestInfoSheet> {
  late Duration? questDuration;

  static const double _aspectRatio = 315 / 375;
  static const double _heightMultiplier = 1.5;
  static const EdgeInsets _contentPadding = EdgeInsets.only(
    top: 0.167,
    left: 0.111,
    right: 0.111,
    bottom: 0.13,
  );

  @override
  void initState() {
    questDuration = widget.quest?.infos?.timeToComplete != null
        ? Duration(milliseconds: widget.quest!.infos!.timeToComplete!)
        : null;
    super.initState();
  }

  @override
  void didUpdateWidget(covariant QuestInfoSheet oldWidget) {
    if (oldWidget.quest != widget.quest) {
      questDuration = widget.quest?.infos?.timeToComplete != null
          ? Duration(milliseconds: widget.quest!.infos!.timeToComplete!)
          : null;
    }
    super.didUpdateWidget(oldWidget);
  }

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
        if (widget.quest != null) _buildContent(sheetWidth, sheetHeight),
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
            if (widget.quest!.prizes != null)
              Expanded(flex: 2, child: _buildRewards()),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestInfo() {
    return Column(
      children: [
        Flexible(
          flex: 1,
          child: AutoSizeText(
            widget.quest!.infos!.title!,
            maxFontSize: 24,
            minFontSize: 10,
            maxLines: 2,
            textAlign: TextAlign.center,
            style: KlimmeckGuideTheme.instance.headlineLarge,
          ),
        ),

        Expanded(
          flex: 4,
          child: Row(
            children: [
              Column(
                children: [
                  if (widget.quest!.infos!.enemy != null)
                    Expanded(
                      flex: 3,
                      child: Image.asset(
                        widget.quest!.infos!.enemy!.imagePath!,
                        fit: BoxFit.contain,
                      ),
                    ),
                  if (widget.quest!.infos!.enemy != null)
                    Expanded(
                      flex: 1,
                      child: AutoSizeText(
                        widget.quest!.infos!.enemy!.name!,
                        maxFontSize: 12,
                        minFontSize: 8,
                        textAlign: TextAlign.center,
                        style: KlimmeckGuideTheme.instance.bodyLarge,
                      ),
                    ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  if (questDuration != null)
                    AutoSizeText(
                      "Tempo richiesto: ${getStringToShowFromDuration(questDuration!)}",
                      maxFontSize: 20,
                      minFontSize: 8,
                      textAlign: TextAlign.left,
                      style: KlimmeckGuideTheme.instance.bodyLarge,
                    ),
                  if (widget.quest!.requirements?.requiredPoints != null)
                    AutoSizeText(
                      "Punti canale richiesti: 3000 / ${widget.quest!.requirements?.requiredPoints}",
                      maxFontSize: 16,
                      minFontSize: 8,
                      maxLines: 1,
                      textAlign: TextAlign.left,
                      style: KlimmeckGuideTheme.instance.bodyLarge,
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

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
                  if (widget.quest!.prizes?.prizeCoins != null)
                    CoinsDisplay(
                      coins: widget.quest!.prizes!.prizeCoins!,
                      height: constraints.maxHeight - 30,
                      width: constraints.maxWidth * 0.5,
                    ),
                  if (widget.quest!.prizes!.prizeItem != null)
                    Flexible(
                      child: widget.quest!.prizes!.prizeItem!.isEquipment
                          ? EquipmentItemCard(
                              isSelected: false,
                              size: constraints.maxHeight - 30,
                              equipmentItem:
                                  widget.quest!.prizes!.prizeItem!.asEquipment!,
                            )
                          : LootItemCard(
                              lootItem:
                                  widget.quest!.prizes!.prizeItem!.asLoot!,
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
