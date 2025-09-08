enum EffectType {
  none(imagePath: "assets/icons/svg/effectTypes/noneEffect.svg"),
  heal(imagePath: "assets/icons/svg/effectTypes/healEffect.svg"),
  hunger(imagePath: "assets/icons/svg/effectTypes/hungerEffect.svg"),
  munition(imagePath: "assets/icons/svg/effectTypes/munitionEffect.svg"),
  exploration(imagePath: "assets/icons/svg/effectTypes/explorationEffect.svg");

  final String imagePath;

  const EffectType({required this.imagePath});
}
