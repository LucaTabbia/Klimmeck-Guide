enum RaceType { dragonborn, elf, gnome, halfling, halfelf, human, dwarf, tiefling, aarakocra }

extension RaceTypeExtension on RaceType {
  String get label {
    switch (this) {
      case RaceType.dragonborn:
        return 'Draconide';
      case RaceType.elf:
        return 'Elfo';
      case RaceType.gnome:
        return 'Gnomo';
      case RaceType.halfling:
        return 'Halfling';
      case RaceType.halfelf:
        return 'Mezzelfo';
      case RaceType.human:
        return 'Umano';
      case RaceType.dwarf:
        return 'Nano';
      case RaceType.tiefling:
        return 'Tiefling';
      case RaceType.aarakocra:
        return 'Aarakocra';
    }
  }
}
