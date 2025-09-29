enum UseType {
  defense(
    imagePath:
        "https://res.cloudinary.com/dzuhywp53/image/upload/v1757660804/defenseUse_tuhdja.svg",
    label: "Difesa",
  ),
  attack(
    imagePath: "https://res.cloudinary.com/dzuhywp53/image/upload/v1757660802/attackUse_plbzx7.svg",
    label: "Attacco",
  ),
  control(
    imagePath:
        "https://res.cloudinary.com/dzuhywp53/image/upload/v1757660807/controlUse_ua2bpj.svg",
    label: "Controllo",
  ),
  illusion(
    imagePath:
        "https://res.cloudinary.com/dzuhywp53/image/upload/v1757660809/illusionUse_gxy4x3.svg",
    label: "Illusione",
  ),
  charm(
    imagePath: "https://res.cloudinary.com/dzuhywp53/image/upload/v1757660815/charmUse_fcehsb.svg",
    label: "Ammaliare",
  ),
  confuse(
    imagePath:
        "https://res.cloudinary.com/dzuhywp53/image/upload/v1757660811/confuseUse_v9ciyh.svg",
    label: "Confondere",
  ),
  enhance(
    imagePath:
        "https://res.cloudinary.com/dzuhywp53/image/upload/v1757660813/enhanceUse_sodazm.svg",
    label: "Potenziare",
  ),
  infuse(
    imagePath: "https://res.cloudinary.com/dzuhywp53/image/upload/v1757660806/infuseUse_rvzfmm.svg",
    label: "Infondere",
  );

  final String imagePath;
  final String label;

  const UseType({required this.label, required this.imagePath});
}
