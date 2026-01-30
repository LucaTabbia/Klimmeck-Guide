import 'package:klimmeck_guide/config/cloudinary_assets.dart';

enum QuestType {
  hunt(imageId: CloudinaryAssets.huntPawn),
  aid(imageId: CloudinaryAssets.aidPawn),
  enemy(imageId: CloudinaryAssets.enemyPawn),
  worldMission(imageId: CloudinaryAssets.worldMissionPawn),
  boss(imageId: CloudinaryAssets.bossPawn),
  dungeon(imageId: CloudinaryAssets.dungeonPawn),
  story(imageId: CloudinaryAssets.storyPawn),
  study(imageId: ''),
  heal(imageId: ''),
  job(imageId: ''),
  crime(imageId: ''),
  guard(imageId: '');

  final String _imageId;

  String get imagePath => _imageId.isEmpty ? '' : CloudinaryAssets.url(_imageId);

  const QuestType({required String imageId}) : _imageId = imageId;
}
