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

extension LoreTypeExtension on LoreType {
  String get name {
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
}
