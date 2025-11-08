import 'package:flutter/material.dart';
import 'package:klimmeck_guide/models/enums/sex_type.dart';
import 'package:klimmeck_guide/models/enums/slot_type.dart';
import 'package:klimmeck_guide/models/equipment.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/components/equipment_area.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/components/equipment_box.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/components/equipment_image.dart';
import 'package:klimmeck_guide/shared/components/cached_svg.dart';

import '../../../../../theme/kg_theme.dart';

class EquipmentMannequin extends StatefulWidget {
  const EquipmentMannequin({
    super.key,
    required this.sexType,
    required this.selectedSlot,
    required this.equipment,
    required this.onTap,
  });

  final SexType sexType;
  final Equipment equipment;
  final SlotType? selectedSlot;
  final Function(SlotType) onTap;

  @override
  State<EquipmentMannequin> createState() => _EquipmentMannequinState();
}

class _EquipmentMannequinState extends State<EquipmentMannequin> {
  final double mannequinAspectRatio = 127.5 / 374.999989;

  @override
  Widget build(BuildContext context) {
    final double mannequinHeight = MediaQuery.of(context).size.height - 30;
    final double mannequinWidth = mannequinHeight * mannequinAspectRatio;

    return SizedBox(
      height: MediaQuery.of(context).size.height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: mannequinWidth + 10,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 15.0),
                  child: SizedBox(
                    width: mannequinWidth,
                    height: mannequinHeight,
                    child: CachedSvg(url: widget.sexType.mannequinPath),
                  ),
                ),
                if (widget.equipment.head != null)
                  EquipmentImage(
                    baseHeight: mannequinHeight,
                    baseWidth: mannequinWidth,
                    imagePath: widget.sexType.helmetPath,
                    ratios: SlotType.head.ratios,
                  ),
                if (widget.equipment.legs != null)
                  EquipmentImage(
                    baseHeight: mannequinHeight,
                    baseWidth: mannequinWidth,
                    imagePath: widget.sexType.gravesPath,
                    ratios: SlotType.legs.ratios,
                  ),
                if (widget.equipment.foots != null)
                  EquipmentImage(
                    baseHeight: mannequinHeight,
                    baseWidth: mannequinWidth,
                    imagePath: widget.sexType.bootsPath,
                    ratios: SlotType.foots.ratios,
                  ),
                if (widget.equipment.chest != null)
                  EquipmentImage(
                    baseHeight: mannequinHeight,
                    baseWidth: mannequinWidth,
                    imagePath: widget.sexType.chestPiecePath,
                    ratios: SlotType.chest.ratios,
                  ),
                if (widget.equipment.arms != null)
                  EquipmentImage(
                    baseHeight: mannequinHeight,
                    baseWidth: mannequinWidth,
                    imagePath: widget.sexType.glovesPath,
                    ratios: SlotType.arms.ratios,
                  ),
                EquipmentArea(
                  selectedSlot: widget.selectedSlot,
                  baseHeight: mannequinHeight,
                  baseWidth: mannequinWidth,
                  slot: SlotType.chest,
                  borderColor: KlimmeckGuideTheme.deepNight,
                  onTap: (slot) => widget.onTap(slot),
                ),
                EquipmentArea(
                  selectedSlot: widget.selectedSlot,
                  baseHeight: mannequinHeight,
                  baseWidth: mannequinWidth,
                  slot: SlotType.foots,
                  borderColor: KlimmeckGuideTheme.darkBronze,
                  onTap: (slot) => widget.onTap(slot),
                ),
                EquipmentArea(
                  baseHeight: mannequinHeight,
                  baseWidth: mannequinWidth,
                  slot: SlotType.legs,
                  borderColor: KlimmeckGuideTheme.royalCrimson,
                  onTap: (slot) => widget.onTap(slot),
                  selectedSlot: widget.selectedSlot,
                ),
                EquipmentArea(
                  baseHeight: mannequinHeight,
                  baseWidth: mannequinWidth,
                  slot: SlotType.head,
                  borderColor: KlimmeckGuideTheme.mysticBlue,
                  onTap: (slot) => widget.onTap(slot),
                  selectedSlot: widget.selectedSlot,
                ),
                EquipmentArea(
                  baseHeight: mannequinHeight,
                  baseWidth: mannequinWidth,
                  slot: SlotType.arms,
                  borderColor: KlimmeckGuideTheme.primaryGold,
                  onTap: (slot) => widget.onTap(slot),
                  selectedSlot: widget.selectedSlot,
                ),
                EquipmentArea(
                  baseHeight: mannequinHeight,
                  baseWidth: mannequinWidth,
                  slot: SlotType.arms,
                  borderColor: KlimmeckGuideTheme.primaryGold,
                  onTap: (slot) => widget.onTap(slot),
                  isRight: true,
                  selectedSlot: widget.selectedSlot,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              children: [
                Spacer(),
                EquipmentBox(
                  selectedBox: widget.selectedSlot,
                  slotType: SlotType.firstAccessory,
                  size: mannequinHeight / 4 - 10,
                  onTap: (slot) => widget.onTap(slot),
                  item: widget.equipment.firstAccessory,
                ),
                Spacer(),
                EquipmentBox(
                  selectedBox: widget.selectedSlot,
                  slotType: SlotType.secondAccessory,
                  size: mannequinHeight / 4 - 10,
                  onTap: (slot) => widget.onTap(slot),
                  item: widget.equipment.secondAccessory,
                ),
                Spacer(),
                EquipmentBox(
                  selectedBox: widget.selectedSlot,
                  slotType: SlotType.leftHand,
                  size: mannequinHeight / 4 - 10,
                  onTap: (slot) => widget.onTap(slot),
                  item: widget.equipment.leftHand,
                ),
                Spacer(),
                EquipmentBox(
                  selectedBox: widget.selectedSlot,
                  slotType: SlotType.rightHand,
                  size: mannequinHeight / 4 - 10,
                  onTap: (slot) => widget.onTap(slot),
                  item: widget.equipment.rightHand,
                ),
                Spacer(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
