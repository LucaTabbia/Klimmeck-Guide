import '../equip_ratios.dart';

const double mannequinBaseHeight = 400;

enum EquipType {
  helm(
    label: "Elmo",
    imagePath: "assets/icons/svg/equipTypes/helmetType.svg",
    ratios: EquipRatios(
      aspectRatio: 1,
      mannequinRatio: mannequinBaseHeight / 80,
      positionRatio: mannequinBaseHeight / 0.01, // <- valore molto grande
      areaHeightRatio: 0.98,
      addedTop: 0,
    ),
  ),
  chestPiece(
    label: "Corazza",
    imagePath: "assets/icons/svg/equipTypes/chestType.svg",
    ratios: EquipRatios(
      aspectRatio: 1,
      mannequinRatio: mannequinBaseHeight / 136,
      positionRatio: mannequinBaseHeight / 70,
      areaHeightRatio: 0.74,
      addedTop: 0.02,
    ),
  ),
  boots(
    label: "Stivali",
    imagePath: "assets/icons/svg/equipTypes/bootsType.svg",
    ratios: EquipRatios(
      aspectRatio: 375 / 374.999991,
      mannequinRatio: mannequinBaseHeight / 117,
      positionRatio: mannequinBaseHeight / 298,
      areaHeightRatio: 1,
      addedTop: 0.01,
    ),
  ),
  greaves(
    label: "Gambali",
    imagePath: "assets/icons/svg/equipTypes/greavesType.svg",
    ratios: EquipRatios(
      aspectRatio: 300 / 337.499995,
      mannequinRatio: mannequinBaseHeight / 145,
      positionRatio: mannequinBaseHeight / 170,
      areaHeightRatio: 0.86,
      addedTop: 0.02,
    ),
  ),
  weapon(
    label: "Arma",
    imagePath: "assets/icons/svg/equipTypes/weaponType.svg",
    ratios: EquipRatios(
      aspectRatio: 1,
      mannequinRatio: mannequinBaseHeight / 85,
      positionRatio: 0,
      areaHeightRatio: 0.7,
      addedTop: 0.1,
    ),
  ),
  shield(
    label: "Scudo",
    imagePath: "assets/icons/svg/equipTypes/shieldType.svg",
    ratios: EquipRatios(
      aspectRatio: 1,
      mannequinRatio: mannequinBaseHeight / 85,
      positionRatio: 0,
      areaHeightRatio: 0.7,
      addedTop: 0.1,
    ),
  ),
  gloves(
    label: "Guanti",
    imagePath: "assets/icons/svg/equipTypes/glovesType.svg",
    ratios: EquipRatios(
      aspectRatio: 375 / 225,
      mannequinRatio: mannequinBaseHeight / 87,
      positionRatio: mannequinBaseHeight / 170,
      areaHeightRatio: 0.98,
      addedTop: 0.01,
    ),
  ),
  ring(
    label: "Anello",
    imagePath: "assets/icons/svg/equipTypes/ringType.svg",
    ratios: EquipRatios(
      aspectRatio: 1,
      mannequinRatio: 0,
      positionRatio: 0,
      areaHeightRatio: 0.7,
      addedTop: 0,
    ),
  ),
  necklace(
    label: "Collana",
    imagePath: "assets/icons/svg/equipTypes/necklaceType.svg",
    ratios: EquipRatios(
      aspectRatio: 1,
      mannequinRatio: 0,
      positionRatio: 0,
      areaHeightRatio: 0.7,
      addedTop: 0,
    ),
  );

  final String label;
  final EquipRatios ratios;
  final String imagePath;

  const EquipType({required this.label, required this.ratios, required this.imagePath});
}
