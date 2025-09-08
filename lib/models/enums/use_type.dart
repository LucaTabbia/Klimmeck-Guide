enum UseType {
  defense(imagePath: "assets/icons/svg/useTypes/defenseUse.svg", label: "Difesa"),
  attack(imagePath: "assets/icons/svg/useTypes/attackUse.svg", label: "Attacco"),
  control(imagePath: "assets/icons/svg/useTypes/controlUse.svg", label: "Controllo"),
  illusion(imagePath: "assets/icons/svg/useTypes/illusionUse.svg", label: "Illusione"),
  charm(imagePath: "assets/icons/svg/useTypes/charmUse.svg", label: "Ammaliare"),
  confuse(imagePath: "assets/icons/svg/useTypes/confuseUse.svg", label: "Confondere"),
  enhance(imagePath: "assets/icons/svg/useTypes/enhanceUse.svg", label: "Potenziare"),
  infuse(imagePath: "assets/icons/svg/useTypes/infuseUse.svg", label: "Infondere");

  final String imagePath;
  final String label;

  const UseType({required this.label, required this.imagePath});
}
