import 'package:klimmeck_guide/config/cloudinary_assets.dart';

enum EnergyType {
  fire(label: "Fuoco", imageId: CloudinaryAssets.fireEnergy),
  cold(label: "Gelo", imageId: CloudinaryAssets.iceEnergy),
  lightning(label: "Fulmine", imageId: CloudinaryAssets.lightningEnergy),
  acid(label: "Acido", imageId: CloudinaryAssets.acidEnergy),
  poison(label: "Veleno", imageId: CloudinaryAssets.poisonEnergy),
  thunder(label: "Tuono", imageId: CloudinaryAssets.thunderEnergy),
  force(label: "Forza", imageId: CloudinaryAssets.forceEnergy),
  necrotic(label: "Necrotico", imageId: CloudinaryAssets.necroticEnergy),
  radiant(label: "Radioso", imageId: CloudinaryAssets.radiantEnergy),
  psychic(label: "Psichico", imageId: CloudinaryAssets.psychicEnergy),
  enhancing(label: "Potenziante", imageId: CloudinaryAssets.enhancingEnergy);

  final String _imageId;
  final String label;

  String get imagePath => CloudinaryAssets.url(_imageId);

  const EnergyType({required this.label, required String imageId}) : _imageId = imageId;
}
