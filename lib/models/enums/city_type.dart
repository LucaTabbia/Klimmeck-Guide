import 'package:klimmeck_guide/config/cloudinary_assets.dart';

enum CityType {
  drusteaCapital(size: 62, imageId: CloudinaryAssets.cliffbreak),
  valanCapital(size: 70, imageId: CloudinaryAssets.valantar),
  mirwaCapital(size: 60, imageId: CloudinaryAssets.mirwen),
  elfCapital(size: 46, imageId: CloudinaryAssets.elfCapital),
  flameNorthCapital(size: 47, imageId: CloudinaryAssets.bellport),
  flameCenterCapital(size: 48, imageId: CloudinaryAssets.virnen),
  flameSouthCapital(size: 50, imageId: CloudinaryAssets.flameSouthCapital),
  motherCapital(size: 60, imageId: CloudinaryAssets.morrulir),
  liberiaCapital(size: 59, imageId: CloudinaryAssets.liberiaCapital),
  ferrionCity(size: 55, imageId: CloudinaryAssets.ferrion),
  necrorianCity(size: 60, imageId: CloudinaryAssets.necrorian),
  talmvereVillage(size: 39, imageId: CloudinaryAssets.talmvere),
  drusteaCity(size: 43, imageId: CloudinaryAssets.drusteaCity),
  drusteaVillage(size: 30, imageId: CloudinaryAssets.drusteaVillage),
  drusteaSeaCity(size: 45, imageId: CloudinaryAssets.drusteaSeaCity),
  aarakocraVillage(size: 30, imageId: CloudinaryAssets.aarakocraVillage),
  valanVillage(size: 30, imageId: CloudinaryAssets.valanVillage),
  valanCity(size: 44, imageId: CloudinaryAssets.valanCity),
  valanSeaCity(size: 45, imageId: CloudinaryAssets.valanSeaCity),
  mirwaCity(size: 44, imageId: CloudinaryAssets.mirwaCity),
  mirwaSeaCity(size: 45, imageId: CloudinaryAssets.mirwaSeaCity),
  mirwaVillage(size: 31, imageId: CloudinaryAssets.mirwaVillage),
  desertVillage(size: 30, imageId: CloudinaryAssets.desertVillage),
  tropicalVillage(size: 30, imageId: CloudinaryAssets.tropicalVillage),
  mountainVillage(size: 30, imageId: CloudinaryAssets.mountainVillage),
  northVillage(size: 30, imageId: CloudinaryAssets.northVillage),
  forestVillage(size: 32, imageId: CloudinaryAssets.forestVillage),
  flameCity(size: 41, imageId: CloudinaryAssets.flameCity),
  flameVillage(size: 34, imageId: CloudinaryAssets.flameVillage),
  motherCity(size: 44, imageId: CloudinaryAssets.motherCity),
  motherVillage(size: 34, imageId: CloudinaryAssets.motherVillage),
  liberiaCity(size: 40, imageId: CloudinaryAssets.liberiaCity),
  liberiaVillage(size: 31, imageId: CloudinaryAssets.liberiaVillage);

  final int size;
  final String _imageId;

  String get imagePath => CloudinaryAssets.url(_imageId);

  const CityType({required this.size, required String imageId})
    : _imageId = imageId;
}
