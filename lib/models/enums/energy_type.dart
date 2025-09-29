enum EnergyType {
  fire(
    label: "Fuoco",
    imagePath:
        "https://res.cloudinary.com/dzuhywp53/image/upload/v1757660512/fireEnergy_cbz3fo.svg",
  ),
  cold(
    label: "Gelo",
    imagePath: "https://res.cloudinary.com/dzuhywp53/image/upload/v1757660519/iceEnergy_igf4o0.svg",
  ),
  lightning(
    label: "Fulmine",
    imagePath:
        "https://res.cloudinary.com/dzuhywp53/image/upload/v1757660512/lightningEnergy_xldvl8.svg",
  ),
  acid(
    label: "Acido",
    imagePath:
        "https://res.cloudinary.com/dzuhywp53/image/upload/v1757660513/acidEnergy_frxlo5.svg",
  ),
  poison(
    label: "Veleno",
    imagePath:
        "https://res.cloudinary.com/dzuhywp53/image/upload/v1757660514/poisonEnergy_vplheq.svg",
  ),
  thunder(
    label: "Tuono",
    imagePath:
        "https://res.cloudinary.com/dzuhywp53/image/upload/v1757660517/thunderEnergy_nx8anb.svg",
  ),
  force(
    label: "Forza",
    imagePath:
        "https://res.cloudinary.com/dzuhywp53/image/upload/v1757660514/forceEnergy_blou6p.svg",
  ),
  necrotic(
    label: "Necrotico",
    imagePath:
        "https://res.cloudinary.com/dzuhywp53/image/upload/v1757660518/necroticEnergy_vknlaj.svg",
  ),
  radiant(
    label: "Radioso",
    imagePath:
        "https://res.cloudinary.com/dzuhywp53/image/upload/v1757660516/radiantEnergy_zhv2ay.svg",
  ),
  psychic(
    label: "Psichico",
    imagePath:
        "https://res.cloudinary.com/dzuhywp53/image/upload/v1757660516/psychicEnergy_isslea.svg",
  ),
  enhancing(
    label: "Potenziante",
    imagePath:
        "https://res.cloudinary.com/dzuhywp53/image/upload/v1757660519/enhancingEnergy_sdt2ao.svg",
  );

  final String imagePath;
  final String label;
  const EnergyType({required this.label, required this.imagePath});
}
