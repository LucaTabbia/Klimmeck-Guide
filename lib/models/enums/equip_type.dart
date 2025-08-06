enum EquipType { helm, chestPiece, boots, greaves, weapon, shield, gloves, accessory }

extension EquipTypeExtension on EquipType {
  String get label {
    switch (this) {
      case EquipType.helm:
        return 'Elmo';
      case EquipType.chestPiece:
        return 'Corazza';
      case EquipType.boots:
        return 'Stivali';
      case EquipType.greaves:
        return 'Gambali';
      case EquipType.gloves:
        return 'Guanti';
      case EquipType.weapon:
        return 'Arma';
      case EquipType.shield:
        return 'Scudo';
      case EquipType.accessory:
        return 'Accessorio';
    }
  }
}
