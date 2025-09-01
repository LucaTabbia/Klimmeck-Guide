import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:klimmeck_guide/shared/components/coins_column.dart';
import 'package:klimmeck_guide/theme/kg_theme.dart';
import 'package:klimmeck_guide/utils/utils.dart';

import '../../../../../models/quest/quest.dart';

class QuestInfoSheet extends StatefulWidget {
  const QuestInfoSheet({super.key, required this.quest});

  final Quest? quest;

  @override
  State<QuestInfoSheet> createState() => _QuestInfoSheetState();
}

class _QuestInfoSheetState extends State<QuestInfoSheet> {
  late Duration? questDuration;

  @override
  void initState() {
    if (widget.quest?.infos?.timeToComplete != null) {
      questDuration = Duration(milliseconds: widget.quest!.infos!.timeToComplete!);
    } else {
      questDuration = null;
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final svgWidth = MediaQuery.of(context).size.height * 1.3 * (315 / 375);
    final svgHeight = MediaQuery.of(context).size.height * 1.3;
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        SvgPicture.asset(
          "assets/icons/svg/sheets/emptySheet.svg",
          height: svgHeight,
          width: svgWidth,
        ),
        if (widget.quest != null)
          SizedBox(
            width: svgWidth,
            height: svgHeight,
            child: Padding(
              padding: EdgeInsets.only(
                top: svgHeight / 6,
                left: svgWidth / 9,
                right: svgWidth / 9,
                bottom: svgHeight / 9,
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SizedBox(
                        height: constraints.maxHeight - (constraints.maxHeight / 2.5),
                        child: Column(
                          children: [
                            SizedBox(
                              height: (constraints.maxHeight - (constraints.maxHeight / 3.5)) / 8,
                              child: AutoSizeText(
                                widget.quest!.infos!.title!,
                                maxFontSize: 24,
                                minFontSize: 10,
                                maxLines: 2,
                                textAlign: TextAlign.center,
                                style: KlimmeckGuideTheme.instance.headlineLarge,
                              ),
                            ),
                            if (widget.quest!.infos!.enemy != null)
                              Image.asset(
                                widget.quest!.infos!.enemy!.imagePath!,
                                height: constraints.maxHeight / 4,
                              ),
                            if (widget.quest!.infos!.enemy != null)
                              SizedBox(
                                height:
                                    (constraints.maxHeight - (constraints.maxHeight / 3.5)) / 15,
                                child: AutoSizeText(
                                  widget.quest!.infos!.enemy!.name!,
                                  maxFontSize: 12,
                                  minFontSize: 10,
                                  textAlign: TextAlign.center,
                                  style: KlimmeckGuideTheme.instance.bodyLarge,
                                ),
                              ),
                            if (questDuration != null)
                              SizedBox(
                                height: (constraints.maxHeight - (constraints.maxHeight / 3.5)) / 9,
                                child: AutoSizeText(
                                  "Tempo richiesto: ${getStringToShowFromDuration(questDuration!)}",
                                  maxFontSize: 20,
                                  minFontSize: 10,
                                  textAlign: TextAlign.center,
                                  style: KlimmeckGuideTheme.instance.bodyLarge,
                                ),
                              ),
                            if (widget.quest!.requirements?.requiredPoints != null)
                              SizedBox(
                                height: (constraints.maxHeight - (constraints.maxHeight / 3.5)) / 9,
                                child: AutoSizeText(
                                  "Punti canale richiesti: 3000 / ${widget.quest!.requirements?.requiredPoints}",
                                  maxFontSize: 20,
                                  minFontSize: 10,
                                  maxLines: 1,
                                  textAlign: TextAlign.center,
                                  style: KlimmeckGuideTheme.instance.bodyLarge,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (widget.quest!.prizes != null)
                        SizedBox(
                          height: constraints.maxHeight / 2.5,
                          child: Column(
                            children: [
                              Align(
                                alignment: Alignment.centerLeft,
                                child: AutoSizeText(
                                  "Ricompense:",
                                  maxFontSize: 20,
                                  minFontSize: 10,
                                  textAlign: TextAlign.left,
                                  style: KlimmeckGuideTheme.instance.specialText,
                                ),
                              ),
                              if (widget.quest!.prizes?.prizeCoins != null)
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: CoinsColumn(
                                    coins: widget.quest!.prizes!.prizeCoins!,
                                    height: constraints.maxHeight / 3.5,
                                    width: constraints.maxWidth / 3,
                                  ),
                                ),
                            ],
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}
