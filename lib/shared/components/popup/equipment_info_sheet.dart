import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:klimmeck_guide/models/enums/equip_type.dart';
import 'package:klimmeck_guide/models/equipment_item.dart';
import 'package:klimmeck_guide/shared/components/cached_svg.dart';
import 'package:klimmeck_guide/shared/components/cards/spell_card.dart';

import '../../../theme/kg_theme.dart';

class EquipmentInfoSheet extends StatefulWidget {
  const EquipmentInfoSheet({
    super.key,
    required this.equipmentItem,
    required this.onEquip,
    required this.isEquipped,
  });

  final EquipmentItem? equipmentItem;
  final VoidCallback onEquip;
  final bool isEquipped;

  @override
  State<EquipmentInfoSheet> createState() => _EquipmentInfoSheetState();
}

class _EquipmentInfoSheetState extends State<EquipmentInfoSheet> {
  @override
  Widget build(BuildContext context) {
    final svgWidth = MediaQuery.of(context).size.height * 1.3 * (315 / 375);
    final svgHeight = MediaQuery.of(context).size.height * 1.3;
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        CachedSvg(
          url:
              "https://res.cloudinary.com/dzuhywp53/image/upload/v1757660751/emptySheet_jiip7r.svg",
          height: svgHeight,
          width: svgWidth,
        ),
        SizedBox(
          width: svgWidth,
          height: svgHeight,
          child: Padding(
            padding: EdgeInsets.only(
              top: svgHeight / 6,
              left: svgWidth / 9,
              right: svgWidth / 9,
              bottom: svgHeight / 8,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (widget.equipmentItem != null) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SizedBox(
                        height: constraints.maxHeight,
                        child: Column(
                          children: [
                            CachedSvg(
                              url: widget.equipmentItem!.equipType!.imagePath,
                              height: constraints.maxHeight / 3,
                              width: constraints.maxHeight / 3,
                            ),
                            SizedBox(
                              height: 30,
                              child: AutoSizeText(
                                maxFontSize: 24,
                                minFontSize: 12,
                                maxLines: 1,
                                textAlign: TextAlign.center,
                                widget.equipmentItem!.name!.toString() ?? "",
                                style: KlimmeckGuideTheme.instance.bodyLarge.copyWith(
                                  color: widget.equipmentItem!.rarity!.color,
                                  fontWeight: FontWeight.w800,
                                  shadows: [
                                    Shadow(
                                      offset: Offset(0, 0),
                                      blurRadius: 0.7,
                                      color: KlimmeckGuideTheme.deepNight.withAlpha(150),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            Expanded(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: constraints.maxWidth / 2 - 0.5,
                                    child: Padding(
                                      padding: const EdgeInsets.only(left: 5.0),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          SizedBox(
                                            height: 30,
                                            width: constraints.maxWidth / 2 - 10,
                                            child: AutoSizeText(
                                              maxFontSize: 24,
                                              minFontSize: 12,
                                              maxLines: 1,
                                              textAlign: TextAlign.left,
                                              "Statistiche: ",
                                              style: KlimmeckGuideTheme.instance.titleMedium,
                                            ),
                                          ),
                                          AutoSizeText(
                                            maxFontSize: 24,
                                            minFontSize: 12,
                                            maxLines: 1,
                                            textAlign: TextAlign.left,
                                            widget.equipmentItem!.equipType != EquipType.weapon
                                                ? "Resistenza base: "
                                                : "Danno base: ",
                                            style: KlimmeckGuideTheme.instance.bodyMedium,
                                          ),
                                          ...List.generate(
                                            widget.equipmentItem!.damages!.base!.length,
                                            (index) {
                                              return Row(
                                                children: [
                                                  CachedSvg(
                                                    url: widget
                                                        .equipmentItem!
                                                        .damages!
                                                        .base![index]
                                                        .type!
                                                        .imagePath,
                                                    height: (constraints.maxWidth / 2) / 4 - 5,
                                                    width: (constraints.maxWidth / 2) / 4 - 5,
                                                  ),
                                                  Padding(
                                                    padding: const EdgeInsets.only(left: 10.0),
                                                    child: Text(
                                                      maxLines: 1,
                                                      textAlign: TextAlign.center,
                                                      widget
                                                          .equipmentItem!
                                                          .damages!
                                                          .base![index]
                                                          .power!
                                                          .toString(),
                                                      style: KlimmeckGuideTheme.instance.bodyMedium,
                                                    ),
                                                  ),
                                                ],
                                              );
                                            },
                                          ),
                                          if (widget.equipmentItem!.damages!.energy != null &&
                                              widget.equipmentItem!.damages!.energy!.isNotEmpty)
                                            AutoSizeText(
                                              maxFontSize: 24,
                                              minFontSize: 12,
                                              maxLines: 1,
                                              textAlign: TextAlign.left,
                                              widget.equipmentItem!.equipType != EquipType.weapon
                                                  ? "Resistenza magica: "
                                                  : "Danno magico: ",
                                              style: KlimmeckGuideTheme.instance.bodyMedium,
                                            ),
                                          if (widget.equipmentItem!.damages!.energy != null &&
                                              widget.equipmentItem!.damages!.energy!.isNotEmpty)
                                            ...List.generate(
                                              widget.equipmentItem!.damages!.energy!.length,
                                              (index) {
                                                return Row(
                                                  children: [
                                                    CachedSvg(
                                                      url: widget
                                                          .equipmentItem!
                                                          .damages!
                                                          .energy![index]
                                                          .type!
                                                          .imagePath,
                                                      height: (constraints.maxWidth / 2) / 4 - 5,
                                                      width: (constraints.maxWidth / 2) / 4 - 5,
                                                    ),
                                                    Padding(
                                                      padding: const EdgeInsets.only(left: 10.0),
                                                      child: Text(
                                                        maxLines: 1,
                                                        textAlign: TextAlign.center,
                                                        widget
                                                            .equipmentItem!
                                                            .damages!
                                                            .energy![index]
                                                            .power!
                                                            .toString(),
                                                        style:
                                                            KlimmeckGuideTheme.instance.bodyMedium,
                                                      ),
                                                    ),
                                                  ],
                                                );
                                              },
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  if (widget.equipmentItem!.addedSpell != null)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 20.0),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          border: Border(
                                            right: BorderSide(
                                              color: KlimmeckGuideTheme.darkBronze,
                                              width: 1,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  if (widget.equipmentItem!.addedSpell != null)
                                    SizedBox(
                                      width: constraints.maxWidth / 2 - 0.5,
                                      child: Padding(
                                        padding: const EdgeInsets.only(left: 20.0),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            SizedBox(
                                              height: 30,
                                              width: constraints.maxWidth / 2 - 10,
                                              child: AutoSizeText(
                                                maxFontSize: 24,
                                                minFontSize: 12,
                                                maxLines: 1,
                                                textAlign: TextAlign.left,
                                                "Magia infusa: ",
                                                style: KlimmeckGuideTheme.instance.titleMedium,
                                              ),
                                            ),
                                            SpellCard(
                                              spell: widget.equipmentItem!.addedSpell!,
                                              size: constraints.maxWidth / 2,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                } else {
                  return Placeholder();
                }
              },
            ),
          ),
        ),
        AnimatedPositioned(
          duration: Duration(milliseconds: 300),
          top: !widget.isEquipped ? -(MediaQuery.of(context).size.height / 5) : 0,
          left: svgWidth / 10,
          child: GestureDetector(
            onTap: () => widget.onEquip(),
            child: RotatedBox(
              quarterTurns: 3,
              child: CachedSvg(
                url:
                    "https://res.cloudinary.com/dzuhywp53/image/upload/v1757683920/bookmarkRed_jms0vk.svg",
                height: MediaQuery.of(context).size.height / 3,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
