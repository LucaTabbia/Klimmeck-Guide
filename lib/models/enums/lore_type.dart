enum LoreType {
  enemy,
  animal,
  plant,
  character,
  city,
  region,
  state,
  religion,
  ceremony,
  god,
  material,
  knowledge,
}

/// Testo italiano del tipo (D-15): `name` resta il nome sul filo.
extension LoreTypeExtension on LoreType {
  String get label {
    switch (this) {
      case LoreType.enemy:
        return 'Mostri';
      case LoreType.animal:
        return 'Animali';
      case LoreType.plant:
        return 'Piante';
      case LoreType.character:
        return 'Personaggi';
      case LoreType.material:
        return 'Materiali';
      case LoreType.knowledge:
        return 'Conoscenze';
      case LoreType.religion:
        return 'Religioni';
      case LoreType.god:
        return 'Divinità';
      case LoreType.ceremony:
        return 'Cerimonie';
      case LoreType.city:
        return 'Città';
      case LoreType.region:
        return 'Regioni';
      case LoreType.state:
        return 'Stati';
    }
  }

  /// Pagine del Bestiario (D-10): la riga del foglio esiti dice «Nuova pagina
  /// del Bestiario» per questi tipi, «Conoscenza appresa» per gli altri.
  bool get isBestiary =>
      this == LoreType.enemy ||
      this == LoreType.animal ||
      this == LoreType.plant;
}
