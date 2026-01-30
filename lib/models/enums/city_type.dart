import 'package:klimmeck_guide/config/cloudinary_assets.dart';
import 'package:klimmeck_guide/models/enums/city_size_type.dart';

enum CityType {
  drusteaCapital(cityClass: CitySizeType.capital, size: 62, imageId: CloudinaryAssets.cliffbreak),
  valanCapital(cityClass: CitySizeType.capital, size: 70, imageId: CloudinaryAssets.valantar),
  mirwaCapital(cityClass: CitySizeType.capital, size: 60, imageId: CloudinaryAssets.mirwen),
  elfCapital(cityClass: CitySizeType.capital, size: 46, imageId: CloudinaryAssets.elfCapital),
  flameNorthCapital(cityClass: CitySizeType.capital, size: 47, imageId: CloudinaryAssets.bellport),
  flameCenterCapital(cityClass: CitySizeType.capital, size: 48, imageId: CloudinaryAssets.virnen),
  flameSouthCapital(cityClass: CitySizeType.capital, size: 50, imageId: CloudinaryAssets.flameSouthCapital),
  motherCapital(cityClass: CitySizeType.capital, size: 60, imageId: CloudinaryAssets.morrulir),
  liberiaCapital(cityClass: CitySizeType.capital, size: 59, imageId: CloudinaryAssets.liberiaCapital),
  ferrionCity(cityClass: CitySizeType.capital, size: 55, imageId: CloudinaryAssets.ferrion),
  necrorianCity(cityClass: CitySizeType.capital, size: 60, imageId: CloudinaryAssets.necrorian),
  talmvereVillage(cityClass: CitySizeType.capital, size: 39, imageId: CloudinaryAssets.talmvere),
  drusteaCity(cityClass: CitySizeType.city, size: 43, imageId: CloudinaryAssets.drusteaCity),
  drusteaVillage(cityClass: CitySizeType.village, size: 30, imageId: CloudinaryAssets.drusteaVillage),
  drusteaSeaCity(cityClass: CitySizeType.city, size: 45, imageId: CloudinaryAssets.drusteaSeaCity),
  aarakocraVillage(cityClass: CitySizeType.village, size: 30, imageId: CloudinaryAssets.aarakocraVillage),
  valanVillage(cityClass: CitySizeType.village, size: 30, imageId: CloudinaryAssets.valanVillage),
  valanCity(cityClass: CitySizeType.city, size: 44, imageId: CloudinaryAssets.valanCity),
  valanSeaCity(cityClass: CitySizeType.city, size: 45, imageId: CloudinaryAssets.valanSeaCity),
  mirwaCity(cityClass: CitySizeType.city, size: 44, imageId: CloudinaryAssets.mirwaCity),
  mirwaSeaCity(cityClass: CitySizeType.city, size: 45, imageId: CloudinaryAssets.mirwaSeaCity),
  mirwaVillage(cityClass: CitySizeType.village, size: 31, imageId: CloudinaryAssets.mirwaVillage),
  desertVillage(cityClass: CitySizeType.village, size: 30, imageId: CloudinaryAssets.desertVillage),
  tropicalVillage(cityClass: CitySizeType.village, size: 30, imageId: CloudinaryAssets.tropicalVillage),
  mountainVillage(cityClass: CitySizeType.village, size: 30, imageId: CloudinaryAssets.mountainVillage),
  northVillage(cityClass: CitySizeType.village, size: 30, imageId: CloudinaryAssets.northVillage),
  forestVillage(cityClass: CitySizeType.village, size: 32, imageId: CloudinaryAssets.forestVillage),
  flameCity(cityClass: CitySizeType.city, size: 41, imageId: CloudinaryAssets.flameCity),
  flameVillage(cityClass: CitySizeType.village, size: 34, imageId: CloudinaryAssets.flameVillage),
  motherCity(cityClass: CitySizeType.city, size: 44, imageId: CloudinaryAssets.motherCity),
  motherVillage(cityClass: CitySizeType.village, size: 34, imageId: CloudinaryAssets.motherVillage),
  liberiaCity(cityClass: CitySizeType.city, size: 40, imageId: CloudinaryAssets.liberiaCity),
  liberiaVillage(cityClass: CitySizeType.village, size: 31, imageId: CloudinaryAssets.liberiaVillage);

  final int size;
  final String _imageId;
  final CitySizeType cityClass;

  String get imagePath => CloudinaryAssets.url(_imageId);

  const CityType({
    required this.size,
    required this.cityClass,
    required String imageId,
  }) : _imageId = imageId;
}
