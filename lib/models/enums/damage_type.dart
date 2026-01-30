import 'package:klimmeck_guide/config/cloudinary_assets.dart';

enum DamageType {
  blunt(label: 'Contundente', imageId: CloudinaryAssets.bluntDamage),
  cut(label: 'Tagliente', imageId: CloudinaryAssets.cutDamage),
  pierce(label: 'Perforante', imageId: CloudinaryAssets.pierceDamage);

  final String _imageId;
  final String label;

  String get imagePath => CloudinaryAssets.url(_imageId);

  const DamageType({required this.label, required String imageId}) : _imageId = imageId;
}
