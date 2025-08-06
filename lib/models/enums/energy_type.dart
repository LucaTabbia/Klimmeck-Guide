enum EnergyType {
  none,
  fire,
  cold,
  lightning,
  acid,
  poison,
  thunder,
  force,
  necrotic,
  radiant,
  psychic,
  enhancing,
}

extension EnergyTypeExtension on EnergyType {
  String get label {
    switch (this) {
      case EnergyType.none:
        return 'Nessuno';
      case EnergyType.fire:
        return 'Fuoco';
      case EnergyType.cold:
        return 'Gelo';
      case EnergyType.lightning:
        return 'Fulmine';
      case EnergyType.acid:
        return 'Acido';
      case EnergyType.poison:
        return 'Veleno';
      case EnergyType.thunder:
        return 'Tuono';
      case EnergyType.force:
        return 'Forza';
      case EnergyType.necrotic:
        return 'Necrotico';
      case EnergyType.radiant:
        return 'Radioso';
      case EnergyType.psychic:
        return 'Psichico';
      case EnergyType.enhancing:
        return 'Potenziante';
    }
  }
}
