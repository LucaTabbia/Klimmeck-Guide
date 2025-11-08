import 'package:klimmeck_guide/models/enums/equip_type.dart';
import 'package:klimmeck_guide/models/equip_ratios.dart';

enum SlotType {
  arms(
    label: "Braccia",
    types: [EquipType.gloves],
    ratios: EquipRatios(
      aspectRatio: 375 / 225,
      mannequinRatio: mannequinBaseHeight / 87,
      positionRatio: mannequinBaseHeight / 170,
      areaHeightRatio: 0.98,
      addedTop: 0.01,
    ),
  ),
  legs(
    label: "Gambe",
    types: [EquipType.greaves],
    ratios: EquipRatios(
      aspectRatio: 300 / 337.499995,
      mannequinRatio: mannequinBaseHeight / 145,
      positionRatio: mannequinBaseHeight / 170,
      areaHeightRatio: 0.86,
      addedTop: 0.02,
    ),
  ),
  leftHand(
    label: "Mano sinistra",
    types: [EquipType.weapon, EquipType.shield],
    ratios: EquipRatios(
      aspectRatio: 1,
      mannequinRatio: mannequinBaseHeight / 85,
      positionRatio: 0,
      areaHeightRatio: 0.7,
      addedTop: 0.1,
    ),
  ),
  rightHand(
    label: "Mano destra",
    types: [EquipType.weapon, EquipType.shield],
    ratios: EquipRatios(
      aspectRatio: 1,
      mannequinRatio: mannequinBaseHeight / 85,
      positionRatio: 0,
      areaHeightRatio: 0.7,
      addedTop: 0.1,
    ),
  ),
  chest(
    label: "Petto",
    types: [EquipType.chestPiece],
    ratios: EquipRatios(
      aspectRatio: 1,
      mannequinRatio: mannequinBaseHeight / 136,
      positionRatio: mannequinBaseHeight / 70,
      areaHeightRatio: 0.74,
      addedTop: 0.02,
    ),
  ),
  head(
    label: "Testa",
    types: [EquipType.helm],
    ratios: EquipRatios(
      aspectRatio: 1,
      mannequinRatio: mannequinBaseHeight / 80,
      positionRatio: mannequinBaseHeight / 0.01,
      areaHeightRatio: 0.98,
      addedTop: 0,
    ),
  ),
  firstAccessory(
    label: "Primo accessorio",
    types: [EquipType.necklace, EquipType.ring],
    ratios: EquipRatios(
      aspectRatio: 1,
      mannequinRatio: 0,
      positionRatio: 0,
      areaHeightRatio: 0.7,
      addedTop: 0,
    ),
  ),
  secondAccessory(
    label: "Secondo accessorio",
    types: [EquipType.necklace, EquipType.ring],
    ratios: EquipRatios(
      aspectRatio: 1,
      mannequinRatio: 0,
      positionRatio: 0,
      areaHeightRatio: 0.7,
      addedTop: 0,
    ),
  ),
  foots(
    label: "Piedi",
    types: [EquipType.boots],
    ratios: EquipRatios(
      aspectRatio: 375 / 374.999991,
      mannequinRatio: mannequinBaseHeight / 117,
      positionRatio: mannequinBaseHeight / 298,
      areaHeightRatio: 1,
      addedTop: 0.01,
    ),
  );

  final String label;
  final List<EquipType> types;
  final EquipRatios ratios;

  const SlotType({
    required this.label,
    required this.types,
    required this.ratios,
  });
}
