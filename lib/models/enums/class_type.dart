enum ClassType {
  barbarian,
  bard,
  cleric,
  druid,
  fighter,
  monk,
  paladin,
  ranger,
  rogue,
  sorcerer,
  warlock,
  wizard,
}

extension ClassTypeExtension on ClassType {
  String get label {
    switch (this) {
      case ClassType.barbarian:
        return 'Barbaro';
      case ClassType.bard:
        return 'Bardo';
      case ClassType.cleric:
        return 'Chierico';
      case ClassType.druid:
        return 'Druido';
      case ClassType.fighter:
        return 'Guerriero';
      case ClassType.monk:
        return 'Monaco';
      case ClassType.paladin:
        return 'Paladino';
      case ClassType.ranger:
        return 'Ranger';
      case ClassType.rogue:
        return 'Ladro';
      case ClassType.sorcerer:
        return 'Stregone';
      case ClassType.warlock:
        return 'Warlock';
      case ClassType.wizard:
        return 'Mago';
    }
  }
}
