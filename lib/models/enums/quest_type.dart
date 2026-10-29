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

  /// Tipo di missione per il giocatore (09-CONTEXT D-03, C2), copy provvisoria (D-19).
  String get label => switch (this) {
    QuestType.hunt => 'Caccia',
    QuestType.aid => 'Soccorso',
    QuestType.enemy => 'Nemico',
    QuestType.worldMission => 'Missione mondiale',
    QuestType.boss => 'Boss',
    QuestType.dungeon => 'Dungeon',
    QuestType.story => 'Storia',
    QuestType.study => 'Studio',
    QuestType.heal => 'Cura',
    QuestType.job => 'Lavoro',
    QuestType.crime => 'Crimine',
    QuestType.guard => 'Guardia',
  };

  const QuestType({required String imageId}) : _imageId = imageId;
}
