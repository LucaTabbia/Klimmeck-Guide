enum DamageType {
  blunt(label: 'Contundente', imagePath: "assets/icons/svg/damageTypes/bluntDamage.svg"),
  cut(label: 'Tagliente', imagePath: "assets/icons/svg/damageTypes/cutDamage.svg"),
  pierce(label: 'Perforante', imagePath: "assets/icons/svg/damageTypes/pierceDamage.svg");

  final String imagePath;
  final String label;
  const DamageType({required this.label, required this.imagePath});
}
