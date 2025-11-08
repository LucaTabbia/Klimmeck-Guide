const double mannequinBaseHeight = 400;

enum EquipType {
  helm(
    label: "Elmo",
    imagePath:
        "https://res.cloudinary.com/dzuhywp53/image/upload/v1757660597/helmetType_u3gvxz.svg",
  ),
  chestPiece(
    label: "Corazza",
    imagePath:
        "https://res.cloudinary.com/dzuhywp53/image/upload/v1757660600/chestType_ythx19.svg",
  ),
  boots(
    label: "Stivali",
    imagePath:
        "https://res.cloudinary.com/dzuhywp53/image/upload/v1757660599/bootsType_w772pg.svg",
  ),
  greaves(
    label: "Gambali",
    imagePath:
        "https://res.cloudinary.com/dzuhywp53/image/upload/v1757660601/greavesType_enhgpl.svg",
  ),
  weapon(
    label: "Arma",
    imagePath:
        "https://res.cloudinary.com/dzuhywp53/image/upload/v1757660594/weaponType_i5qe0s.svg",
  ),
  shield(
    label: "Scudo",
    imagePath:
        "https://res.cloudinary.com/dzuhywp53/image/upload/v1757660603/shieldType_mbquox.svg",
  ),
  gloves(
    label: "Guanti",
    imagePath:
        "https://res.cloudinary.com/dzuhywp53/image/upload/v1757660596/glovesType_dyybio.svg",
  ),
  ring(
    label: "Anello",
    imagePath:
        "https://res.cloudinary.com/dzuhywp53/image/upload/v1757660595/ringType_qmb6bn.svg",
  ),
  necklace(
    label: "Collana",
    imagePath:
        "https://res.cloudinary.com/dzuhywp53/image/upload/v1757660598/necklaceType_wrpomm.svg",
  );

  final String label;
  final String imagePath;

  const EquipType({required this.label, required this.imagePath});
}
