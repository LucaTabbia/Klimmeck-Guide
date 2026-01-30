import 'package:klimmeck_guide/config/cloudinary_assets.dart';

const double mannequinBaseHeight = 400;

enum EquipType {
  helm(label: "Elmo", imageId: CloudinaryAssets.helmetType),
  chestPiece(label: "Corazza", imageId: CloudinaryAssets.chestType),
  boots(label: "Stivali", imageId: CloudinaryAssets.bootsType),
  greaves(label: "Gambali", imageId: CloudinaryAssets.greavesType),
  weapon(label: "Arma", imageId: CloudinaryAssets.weaponType),
  shield(label: "Scudo", imageId: CloudinaryAssets.shieldType),
  gloves(label: "Guanti", imageId: CloudinaryAssets.glovesType),
  ring(label: "Anello", imageId: CloudinaryAssets.ringType),
  necklace(label: "Collana", imageId: CloudinaryAssets.necklaceType);

  final String label;
  final String _imageId;

  String get imagePath => CloudinaryAssets.url(_imageId);

  const EquipType({required this.label, required String imageId}) : _imageId = imageId;
}
