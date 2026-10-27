import 'package:klimmeck_guide/config/cloudinary_assets.dart';

enum EffectType {
  none(label: 'Nessun effetto', imageId: CloudinaryAssets.noneEffect),
  heal(label: 'Cura', imageId: CloudinaryAssets.healEffect),
  hunger(label: 'Sazietà', imageId: CloudinaryAssets.hungerEffect),
  munition(label: 'Danno', imageId: CloudinaryAssets.munitionEffect),
  exploration(
    label: 'Esplorazione',
    imageId: CloudinaryAssets.explorationEffect,
  );

  final String _imageId;
  final String label;

  String get imagePath => CloudinaryAssets.url(_imageId);

  const EffectType({required this.label, required String imageId})
    : _imageId = imageId;
}
