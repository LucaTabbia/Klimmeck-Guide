import 'package:klimmeck_guide/config/cloudinary_assets.dart';

enum EffectType {
  none(imageId: CloudinaryAssets.noneEffect),
  heal(imageId: CloudinaryAssets.healEffect),
  hunger(imageId: CloudinaryAssets.hungerEffect),
  munition(imageId: CloudinaryAssets.munitionEffect),
  exploration(imageId: CloudinaryAssets.explorationEffect);

  final String _imageId;

  String get imagePath => CloudinaryAssets.url(_imageId);

  const EffectType({required String imageId}) : _imageId = imageId;
}
