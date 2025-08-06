enum UseType { defense, attack, control, illusion, charm, confuse, enhance, infuse }

extension UseTypeExtension on UseType {
  String get label {
    switch (this) {
      case UseType.defense:
        return 'Difesa';
      case UseType.attack:
        return 'Attacco';
      case UseType.control:
        return 'Controllo';
      case UseType.illusion:
        return 'Illusione';
      case UseType.charm:
        return 'Ammaliare';
      case UseType.confuse:
        return 'Confondere';
      case UseType.enhance:
        return 'Potenziare';
      case UseType.infuse:
        return 'Infondere';
    }
  }
}
