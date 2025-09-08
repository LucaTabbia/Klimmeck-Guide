enum EnergyType {
  fire(label: "Fuoco", imagePath: "assets/icons/svg/energyTypes/fireEnergy.svg"),
  cold(label: "Gelo", imagePath: "assets/icons/svg/energyTypes/coldEnergy.svg"),
  lightning(label: "Fulmine", imagePath: "assets/icons/svg/energyTypes/lightningEnergy.svg"),
  acid(label: "Acido", imagePath: "assets/icons/svg/energyTypes/acidEnergy.svg"),
  poison(label: "Veleno", imagePath: "assets/icons/svg/energyTypes/poisonEnergy.svg"),
  thunder(label: "Tuono", imagePath: "assets/icons/svg/energyTypes/thunderEnergy.svg"),
  force(label: "Forza", imagePath: "assets/icons/svg/energyTypes/forceEnergy.svg"),
  necrotic(label: "Necrotico", imagePath: "assets/icons/svg/energyTypes/necroticEnergy.svg"),
  radiant(label: "Radioso", imagePath: "assets/icons/svg/energyTypes/radiantEnergy.svg"),
  psychic(label: "Psichico", imagePath: "assets/icons/svg/energyTypes/psychicEnergy.svg"),
  enhancing(label: "Potenziante", imagePath: "assets/icons/svg/energyTypes/enhancingEnergy.svg");

  final String imagePath;
  final String label;
  const EnergyType({required this.label, required this.imagePath});
}
