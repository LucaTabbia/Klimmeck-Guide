import '../equip_ratios.dart';

const double mannequinBaseHeight = 400;

enum EquipType {
  helm(
    label: "Elmo",
    imagePath:
        "https://res.cloudinary.com/dzuhywp53/image/upload/v1757660597/helmetType_u3gvxz.svg",
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
    imagePath: "https://res.cloudinary.com/dzuhywp53/image/upload/v1757660600/chestType_ythx19.svg",
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
    imagePath: "https://res.cloudinary.com/dzuhywp53/image/upload/v1757660599/bootsType_w772pg.svg",
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
    imagePath:
        "https://res.cloudinary.com/dzuhywp53/image/upload/v1757660601/greavesType_enhgpl.svg",
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
    imagePath:
        "https://res.cloudinary.com/dzuhywp53/image/upload/v1757660594/weaponType_i5qe0s.svg",
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
    imagePath:
        "https://res.cloudinary.com/dzuhywp53/image/upload/v1757660603/shieldType_mbquox.svg",
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
    imagePath:
        "https://res.cloudinary.com/dzuhywp53/image/upload/v1757660596/glovesType_dyybio.svg",
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
    imagePath: "https://res.cloudinary.com/dzuhywp53/image/upload/v1757660595/ringType_qmb6bn.svg",
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
    imagePath:
        "https://res.cloudinary.com/dzuhywp53/image/upload/v1757660598/necklaceType_wrpomm.svg",
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
