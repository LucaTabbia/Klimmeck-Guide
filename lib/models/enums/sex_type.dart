enum SexType { male, female }

extension SextTypeExtension on SexType {
  String get pawnPath {
    switch (this) {
      case SexType.female:
        return "assets/icons/svg/pawns/adventurerFemalePawn.svg";
      case SexType.male:
        return "assets/icons/svg/pawns/adventurerMalePawn.svg";
    }
  }

  String get helmetPath {
    switch (this) {
      case SexType.female:
        return "assets/icons/svg/equipment/femaleHelmet.svg";
      case SexType.male:
        return "assets/icons/svg/equipment/maleHelmet.svg";
    }
  }

  String get chestPiecePath {
    switch (this) {
      case SexType.female:
        return "assets/icons/svg/equipment/femaleChestPiece.svg";
      case SexType.male:
        return "assets/icons/svg/equipment/maleChestPiece.svg";
    }
  }

  String get glovesPath {
    switch (this) {
      case SexType.female:
        return "assets/icons/svg/equipment/femaleGloves.svg";
      case SexType.male:
        return "assets/icons/svg/equipment/maleGloves.svg";
    }
  }

  String get bootsPath {
    switch (this) {
      case SexType.female:
        return "assets/icons/svg/equipment/femaleBoots.svg";
      case SexType.male:
        return "assets/icons/svg/equipment/maleBoots.svg";
    }
  }

  String get gravesPath {
    switch (this) {
      case SexType.female:
        return "assets/icons/svg/equipment/skirt.svg";
      case SexType.male:
        return "assets/icons/svg/equipment/pants.svg";
    }
  }

  String get mannequinPath {
    switch (this) {
      case SexType.female:
        return "assets/icons/svg/equipment/femaleMannequin.svg";
      case SexType.male:
        return "assets/icons/svg/equipment/maleMannequin.svg";
    }
  }
}
