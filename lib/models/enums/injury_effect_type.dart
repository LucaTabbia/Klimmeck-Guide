import 'package:klimmeck_guide/config/cloudinary_assets.dart';

enum InjuryEffect {
  movementImpairment(imageId: CloudinaryAssets.movementInjury),
  visionLoss(imageId: CloudinaryAssets.visionInjury),
  bleeding(imageId: CloudinaryAssets.bleedingInjury),
  pain(imageId: CloudinaryAssets.painInjury),
  paralysis(imageId: CloudinaryAssets.paralysisInjury),
  infection(imageId: CloudinaryAssets.infectionInjury),
  consciousnessLoss(imageId: CloudinaryAssets.consciousnessInjury),
  staminaDrain(imageId: CloudinaryAssets.staminaInjury),
  poisoned(imageId: CloudinaryAssets.poisonInjury),
  burned(imageId: CloudinaryAssets.burnInjury);

  final String _imageId;

  String get imagePath => CloudinaryAssets.url(_imageId);

  const InjuryEffect({required String imageId}) : _imageId = imageId;
}
