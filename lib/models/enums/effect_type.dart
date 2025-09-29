enum EffectType {
  none(
    imagePath:
        "https://res.cloudinary.com/dzuhywp53/image/upload/v1757660482/noneEffect_e6g4b5.svg",
  ),
  heal(
    imagePath:
        "https://res.cloudinary.com/dzuhywp53/image/upload/v1757660480/healEffect_jc9bsg.svg",
  ),
  hunger(
    imagePath:
        "https://res.cloudinary.com/dzuhywp53/image/upload/v1757660483/hungerEffect_mxqqze.svg",
  ),
  munition(
    imagePath:
        "https://res.cloudinary.com/dzuhywp53/image/upload/v1757660484/munitionEffect_cdhllj.svg",
  ),
  exploration(
    imagePath:
        "https://res.cloudinary.com/dzuhywp53/image/upload/v1757660481/explorationEffect_owljlv.svg",
  );

  final String imagePath;

  const EffectType({required this.imagePath});
}
