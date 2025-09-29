import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:klimmeck_guide/models/enums/equip_type.dart';
import 'package:klimmeck_guide/models/enums/sex_type.dart';
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
    required this.selectedTypes,
    required this.equipment,
    required this.onTap,
  });

  final SexType sexType;
  final Equipment equipment;
  final List<EquipType>? selectedTypes;
  final Function(List<EquipType>, bool) onTap;

  @override
  State<EquipmentMannequin> createState() => _EquipmentMannequinState();
}

class _EquipmentMannequinState extends State<EquipmentMannequin> {
  final double mannequinAspectRatio = 127.5 / 374.999989;
  int? selectedBox;

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
                    type: EquipType.helm,
                  ),
                if (widget.equipment.legs != null)
                  EquipmentImage(
                    baseHeight: mannequinHeight,
                    baseWidth: mannequinWidth,
                    imagePath: widget.sexType.gravesPath,
                    type: EquipType.greaves,
                  ),
                if (widget.equipment.foots != null)
                  EquipmentImage(
                    baseHeight: mannequinHeight,
                    baseWidth: mannequinWidth,
                    imagePath: widget.sexType.bootsPath,
                    type: EquipType.boots,
                  ),
                if (widget.equipment.chest != null)
                  EquipmentImage(
                    baseHeight: mannequinHeight,
                    baseWidth: mannequinWidth,
                    imagePath: widget.sexType.chestPiecePath,
                    type: EquipType.chestPiece,
                  ),
                if (widget.equipment.arms != null)
                  EquipmentImage(
                    baseHeight: mannequinHeight,
                    baseWidth: mannequinWidth,
                    imagePath: widget.sexType.glovesPath,
                    type: EquipType.gloves,
                  ),
                EquipmentArea(
                  selectedTypes: widget.selectedTypes,
                  baseHeight: mannequinHeight,
                  baseWidth: mannequinWidth,
                  type: EquipType.chestPiece,
                  borderColor: KlimmeckGuideTheme.deepNight,
                  onTap: (types) => selectBox(0, types),
                ),
                EquipmentArea(
                  selectedTypes: widget.selectedTypes,
                  baseHeight: mannequinHeight,
                  baseWidth: mannequinWidth,
                  type: EquipType.boots,
                  borderColor: KlimmeckGuideTheme.darkBronze,
                  onTap: (types) => selectBox(0, types),
                ),
                EquipmentArea(
                  baseHeight: mannequinHeight,
                  baseWidth: mannequinWidth,
                  type: EquipType.greaves,
                  borderColor: KlimmeckGuideTheme.royalCrimson,
                  onTap: (types) => selectBox(0, types),
                  selectedTypes: widget.selectedTypes,
                ),
                EquipmentArea(
                  baseHeight: mannequinHeight,
                  baseWidth: mannequinWidth,
                  type: EquipType.helm,
                  borderColor: KlimmeckGuideTheme.mysticBlue,
                  onTap: (types) => selectBox(0, types),
                  selectedTypes: widget.selectedTypes,
                ),
                EquipmentArea(
                  baseHeight: mannequinHeight,
                  baseWidth: mannequinWidth,
                  type: EquipType.gloves,
                  borderColor: KlimmeckGuideTheme.primaryGold,
                  onTap: (types) => selectBox(0, types),
                  selectedTypes: widget.selectedTypes,
                ),
                EquipmentArea(
                  baseHeight: mannequinHeight,
                  baseWidth: mannequinWidth,
                  type: EquipType.gloves,
                  borderColor: KlimmeckGuideTheme.primaryGold,
                  onTap: (types) => selectBox(0, types),
                  isRight: true,
                  selectedTypes: widget.selectedTypes,
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
                  selectedBox: selectedBox,
                  index: 1,
                  size: mannequinHeight / 4 - 10,
                  expectedTypes: [EquipType.necklace, EquipType.ring],
                  onTap: selectBox,
                  item: widget.equipment.firstAccessory,
                ),
                Spacer(),
                EquipmentBox(
                  selectedBox: selectedBox,
                  index: 2,
                  size: mannequinHeight / 4 - 10,
                  expectedTypes: [EquipType.necklace, EquipType.ring],
                  onTap: selectBox,
                  item: widget.equipment.secondAccessory,
                ),
                Spacer(),
                EquipmentBox(
                  selectedBox: selectedBox,
                  index: 3,
                  size: mannequinHeight / 4 - 10,
                  expectedTypes: [EquipType.weapon, EquipType.shield],
                  onTap: selectBox,
                  item: widget.equipment.leftHand,
                ),
                Spacer(),
                EquipmentBox(
                  selectedBox: selectedBox,
                  index: 4,
                  size: mannequinHeight / 4 - 10,
                  expectedTypes: [EquipType.weapon, EquipType.shield],
                  onTap: selectBox,
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

  void selectBox(int index, List<EquipType> types) {
    bool isSame = selectedBox == index && listEquals(types, widget.selectedTypes);
    setState(() {
      selectedBox = isSame ? 0 : index;
    });
    widget.onTap(types, isSame);
  }
}
