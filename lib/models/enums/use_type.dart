import 'package:klimmeck_guide/config/cloudinary_assets.dart';

enum UseType {
  defense(
    imageId: CloudinaryAssets.defenseUse,
    label: "Difesa",
  ),
  attack(
    imageId: CloudinaryAssets.attackUse,
    label: "Attacco",
  ),
  control(
    imageId: CloudinaryAssets.controlUse,
    label: "Controllo",
  ),
  illusion(
    imageId: CloudinaryAssets.illusionUse,
    label: "Illusione",
  ),
  charm(
    imageId: CloudinaryAssets.charmUse,
    label: "Ammaliare",
  ),
  confuse(
    imageId: CloudinaryAssets.confuseUse,
    label: "Confondere",
  ),
  enhance(
    imageId: CloudinaryAssets.enhanceUse,
    label: "Potenziare",
  ),
  infuse(
    imageId: CloudinaryAssets.infuseUse,
    label: "Infondere",
  );

  final String _imageId;
  final String label;

  String get imagePath => CloudinaryAssets.url(_imageId);

  const UseType({required this.label, required String imageId}) : _imageId = imageId;
}
