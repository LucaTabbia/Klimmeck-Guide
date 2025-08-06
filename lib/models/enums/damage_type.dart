enum DamageType { blunt, cut, pierce }

extension DamageTypeExtension on DamageType {
  String get label {
    switch (this) {
      case DamageType.blunt:
        return 'Contundente';
      case DamageType.cut:
        return 'Tagliente';
      case DamageType.pierce:
        return 'Perforante';
    }
  }
}
