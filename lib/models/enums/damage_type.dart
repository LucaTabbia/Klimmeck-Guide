enum DamageType {
  blunt(
    label: 'Contundente',
    imagePath:
        "https://res.cloudinary.com/dzuhywp53/image/upload/v1757660455/bluntDamage_wwusuu.svg",
  ),
  cut(
    label: 'Tagliente',
    imagePath:
        "https://res.cloudinary.com/dzuhywp53/image/upload/v1757660749/huntTornSheet2_kqqouj.svg",
  ),
  pierce(
    label: 'Perforante',
    imagePath:
        "https://res.cloudinary.com/dzuhywp53/image/upload/v1757660455/pierceDamage_lr2wyv.svg",
  );

  final String imagePath;
  final String label;
  const DamageType({required this.label, required this.imagePath});
}
