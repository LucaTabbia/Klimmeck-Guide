enum SexType { male, female }

extension SextTypeExtension on SexType {
  String get pawnPath {
    switch (this) {
      case SexType.female:
        return "https://res.cloudinary.com/dzuhywp53/image/upload/v1757660709/adventurerFemalePawn_btrphw.svg";
      case SexType.male:
        return "https://res.cloudinary.com/dzuhywp53/image/upload/v1757660710/adventurerMalePawn_eruq7l.svg";
    }
  }

  String get helmetPath {
    switch (this) {
      case SexType.female:
        return "https://res.cloudinary.com/dzuhywp53/image/upload/v1757682307/femaleHelmet_owbdne.svg";
      case SexType.male:
        return "https://res.cloudinary.com/dzuhywp53/image/upload/v1757660564/maleHelmet_zcqpao.svg";
    }
  }

  String get chestPiecePath {
    switch (this) {
      case SexType.female:
        return "https://res.cloudinary.com/dzuhywp53/image/upload/v1757660571/femaleChestPiece_g3xa67.svg";
      case SexType.male:
        return "https://res.cloudinary.com/dzuhywp53/image/upload/v1757660572/maleChestPiece_ao3f8d.svg";
    }
  }

  String get glovesPath {
    switch (this) {
      case SexType.female:
        return "https://res.cloudinary.com/dzuhywp53/image/upload/v1757660562/femaleGloves_v09nho.svg";
      case SexType.male:
        return "https://res.cloudinary.com/dzuhywp53/image/upload/v1757660570/maleGloves_vw0mf1.svg";
    }
  }

  String get bootsPath {
    switch (this) {
      case SexType.female:
        return "https://res.cloudinary.com/dzuhywp53/image/upload/v1757660573/femaleBoots_ptmefq.svg";
      case SexType.male:
        return "https://res.cloudinary.com/dzuhywp53/image/upload/v1757660560/maleBoots_pyhlnf.svg";
    }
  }

  String get gravesPath {
    switch (this) {
      case SexType.female:
        return "https://res.cloudinary.com/dzuhywp53/image/upload/v1757660574/skirt_cfenoz.svg";
      case SexType.male:
        return "https://res.cloudinary.com/dzuhywp53/image/upload/v1757660563/pants_hrweqf.svg";
    }
  }

  String get mannequinPath {
    switch (this) {
      case SexType.female:
        return "https://res.cloudinary.com/dzuhywp53/image/upload/v1757660559/femaleMannequin_y04ola.svg";
      case SexType.male:
        return "https://res.cloudinary.com/dzuhywp53/image/upload/v1757660558/maleMannequin_ll7j5l.svg";
    }
  }
}
