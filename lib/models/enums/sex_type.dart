import 'package:klimmeck_guide/config/cloudinary_assets.dart';

enum SexType { male, female }

extension SextTypeExtension on SexType {
  String get pawnPath {
    switch (this) {
      case SexType.female:
        return CloudinaryAssets.url(CloudinaryAssets.adventurerFemalePawn);
      case SexType.male:
        return CloudinaryAssets.url(CloudinaryAssets.adventurerMalePawn);
    }
  }

  String get helmetPath {
    switch (this) {
      case SexType.female:
        return CloudinaryAssets.url(CloudinaryAssets.femaleHelmet);
      case SexType.male:
        return CloudinaryAssets.url(CloudinaryAssets.maleHelmet);
    }
  }

  String get chestPiecePath {
    switch (this) {
      case SexType.female:
        return CloudinaryAssets.url(CloudinaryAssets.femaleChestPiece);
      case SexType.male:
        return CloudinaryAssets.url(CloudinaryAssets.maleChestPiece);
    }
  }

  String get glovesPath {
    switch (this) {
      case SexType.female:
        return CloudinaryAssets.url(CloudinaryAssets.femaleGloves);
      case SexType.male:
        return CloudinaryAssets.url(CloudinaryAssets.maleGloves);
    }
  }

  String get bootsPath {
    switch (this) {
      case SexType.female:
        return CloudinaryAssets.url(CloudinaryAssets.femaleBoots);
      case SexType.male:
        return CloudinaryAssets.url(CloudinaryAssets.maleBoots);
    }
  }

  String get gravesPath {
    switch (this) {
      case SexType.female:
        return CloudinaryAssets.url(CloudinaryAssets.skirt);
      case SexType.male:
        return CloudinaryAssets.url(CloudinaryAssets.pants);
    }
  }

  String get mannequinPath {
    switch (this) {
      case SexType.female:
        return CloudinaryAssets.url(CloudinaryAssets.femaleMannequin);
      case SexType.male:
        return CloudinaryAssets.url(CloudinaryAssets.maleMannequin);
    }
  }
}
